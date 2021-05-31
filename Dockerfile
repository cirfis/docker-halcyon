FROM php:fpm as builder

# Setup necessary env vars
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# PHP dependencies
# Basic Prep
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    zlib1g-dev libicu-dev build-essential libcurl4-openssl-dev curl libonig-dev\
    && docker-php-ext-install -j$(nproc) intl \
    && docker-php-ext-install -j$(nproc) mbstring \
    && docker-php-ext-install -j$(nproc) curl \
    && docker-php-ext-install gettext 

# Halcyon
WORKDIR /opt/halcyon
RUN apt-get install -y --no-install-recommends git \
    && git clone https://notabug.org/halcyon-suite/halcyon.git /opt/halcyon/ \
    && git checkout `git describe --tags` \
    && cp -r /opt/halcyon/config /opt/halcyon/config.example \
    && chown -R www-data: /opt/halcyon

# PHP-fpm
# Bring php-fpm configs into a more controllable state
RUN rm /usr/local/etc/php-fpm.d/www.conf.default \
    && mv /usr/local/etc/php-fpm.d/docker.conf /usr/local/etc/php-fpm.d/00-docker.conf \
    && mv /usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/10-www.conf \
    && mv /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/20-docker.conf

from php:fpm as base
# Setup necessary env vars
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Add supervisor and nginx
RUN apt-get update \
    && apt-get install -y --no-install-recommends  supervisor locales nginx

# Setup locales
COPY locale/default /etc/default/locale
COPY locale/locale.gen /etc/locale.gen
RUN locale-gen

# Copy necessary configs
COPY --from=builder	/opt/halcyon			/opt/halcyon
COPY --from=builder	/opt/halcyon			/var/www
COPY --from=builder	/usr/local/php			/usr/local/php
COPY --from=builder	/usr/local/etc/php-fpm.d	/usr/local/etc/php-fpm.d
COPY --from=builder	/usr/local/include/php		/usr/local/include/php
COPY --from=builder	/usr/local/lib/php		/usr/local/lib/php

ADD etc/ /etc/
ADD usr/ /usr/

EXPOSE 80

ENTRYPOINT ["/usr/bin/supervisord","-n","-c","/etc/supervisord.conf"]
