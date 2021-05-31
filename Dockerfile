FROM php:fpm-stretch as builder

# Setup necessary env vars
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# PHP dependencies
# Basic Prep
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    zlib1g-dev libicu-dev build-essential libcurl4-openssl-dev curl \
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
# Bring php-fpm configs into a more controallable state
#RUN rm /usr/local/etc/php-fpm.d/www.conf.default \
#    && mv /usr/local/etc/php-fpm.d/docker.conf /usr/local/etc/php-fpm.d/00-docker.conf \
#    && mv /usr/local/etc/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/10-www.conf \
#    && mv /usr/local/etc/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/20-docker.conf

from php:apache-stretch
# Setup necessary env vars
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Add supervisor
RUN apt-get update \
    && apt-get install -y --no-install-recommends  supervisor locales

# Setup locales
COPY locale/default /etc/default/locale
COPY locale/locale.gen /etc/locale.gen
RUN locale-gen

# Copy necessary configs
#COPY --from=builder	/usr/local/etc/php-fpm.d	/usr/local/etc/php-fpm.d
COPY --from=builder	/opt/halcyon		/opt/halcyon
COPY --from=builder	/usr/local/include/php	/usr/local/include/php
COPY --from=builder	/usr/local/lib/php		/usr/local/lib/php
COPY --from=builder	/usr/local/php		/usr/local/php

ADD etc/ /etc/
ADD usr/ /usr/

# Stop and disable apache2 so supervisor can run it
RUN /etc/init.d/apache2 stop && rm -f /etc/init.d/apache2

EXPOSE 80

ENTRYPOINT ["/usr/bin/supervisord","-c","/etc/supervisord.conf"]
