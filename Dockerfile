FROM php:apache-stretch

# Setup necessary env vars
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Basic Prep
RUN apt-get update \
    && apt-get install -y  --no-install-recommends supervisor curl

# Setup locales
RUN apt-get install -y --no-install-recommends locales
COPY locale/default /etc/default/locale
COPY locale/locale.gen /etc/locale.gen
RUN locale-gen

# PHP dependencies
RUN apt-get install -y --no-install-recommends \
    zlib1g-dev libicu-dev build-essential libcurl4-openssl-dev \
    && docker-php-ext-install -j$(nproc) intl \
    && docker-php-ext-install -j$(nproc) mbstring \
    && docker-php-ext-install -j$(nproc) curl \
    && docker-php-ext-install gettext \
    && apt-get remove -y --purge zlib1g-dev libicu-dev build-essential libcurl4-openssl-dev \
    && apt-get autoremove -y --purge

# Halcyon
WORKDIR /opt/halcyon
RUN apt-get install -y --no-install-recommends git \
    && git clone https://notabug.org/halcyon-suite/halcyon.git /opt/halcyon/ \
    && git checkout `git describe --tags` \
    && cp -r /opt/halcyon/config /opt/halcyon/config.example \
    && chown -R www-data: /opt/halcyon && chmod -R a+X,og+rw /opt/halcyon ; \
	ln -s /opt/halcyon /var/www

# Copy necessary configs
ADD etc/ /etc/
ADD usr/ /usr/

EXPOSE 80

ENTRYPOINT ["/usr/bin/supervisord","-c","/etc/supervisord.conf"]
