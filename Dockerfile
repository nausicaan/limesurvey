FROM php:8.3-fpm

# Runtime variables
ARG VERSION="6.5.8+240517"
ARG USER="1014150000"
ARG DIR="/data/limesurvey"

# Install Composer
COPY --from=composer/composer:latest-bin /composer /usr/bin/composer

# PHP Core and WordPress Extensions
RUN apt-get update && apt-get install -y \
        libldap2-dev \
        libfreetype6-dev \
        libjpeg-dev \
        libonig-dev \
        zlib1g-dev \
        libc-client-dev \
        libkrb5-dev \
        libpng-dev \
        libpq-dev \
        libzip-dev \
        libtidy-dev \
        libsodium-dev \
        libicu-dev \
    && docker-php-ext-configure intl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install -j$(nproc) gd imap ldap intl mbstring mysqli pdo pdo_mysql zip \
    && mkdir -p ${DIR}

WORKDIR ${DIR}

# Download and unzip LimeSurvey from GitHub
ADD "https://github.com/LimeSurvey/LimeSurvey/archive/refs/tags/${VERSION}.tar.gz" limesurvey.tar.gz

RUN tar -xzf limesurvey.tar.gz --strip-components=1 \
    && rm limesurvey.tar.gz \
    # Claim ownership for the OpenShift default user (unique per namespace)
    && chown -R ${USER}:root /data \
    && chmod -R 777 /data/limesurvey/tmp \
    && chmod -R 777 /data/limesurvey/upload \
    && chmod -R 777 /data/limesurvey/application/config