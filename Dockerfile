FROM php:cli-alpine3.12

ENV PSR_VERSION=0.7.0
ENV PHALCON_VERSION=4.0.5
ENV EXT_RDKAFKA_VERSION=4.0.3
ENV LIBRDKAFKA_VERSION=1.4.0
ENV BUILD_DEPS 'autoconf git gcc g++ make bash openssh curl-dev zlib-dev'

RUN apk --no-cache upgrade \
    && apk add $BUILD_DEPS

RUN apk add --no-cache libzip-dev rabbitmq-c-dev icu-dev git \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && php -r "unlink('composer-setup.php');" \
    && curl -L -o /tmp/php-psr.tar.gz https://github.com/jbboehr/php-psr/archive/v${PSR_VERSION}.tar.gz \
    && tar xzf /tmp/php-psr.tar.gz -C /tmp \
    && rm -f /tmp/php-psr.tar.gz \
    && mkdir -p /usr/src/php/ext/php-psr \
    && mv /tmp/php-psr-${PSR_VERSION}/* /usr/src/php/ext/php-psr \
    && rm -rf /tmp/php-psr-${PSR_VERSION} \
    && curl -sSL -o /usr/local/bin/install-php-extensions https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions \
    && chmod +x /usr/local/bin/install-php-extensions \
    && /usr/local/bin/install-php-extensions decimal zip pgsql pdo pdo_pgsql intl php-psr bcmath redis apcu pcntl \
    && rm -f /usr/local/bin/install-php-extensions \
    && rm -rf /usr/src/php \
    && curl -L -o /tmp/phalcon.tar.gz https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz \
    && tar xzf /tmp/phalcon.tar.gz -C /tmp \
    && rm -f /tmp/phalcon.tar.gz \
    && cd /tmp/cphalcon-${PHALCON_VERSION}/build \
    && sh install \
    && echo "extension=phalcon.so" > $PHP_INI_DIR/conf.d/90-phalcon.ini \
    && version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;")

RUN git clone --depth 1 --branch v$LIBRDKAFKA_VERSION https://github.com/edenhill/librdkafka.git /tmp/librdkafka/ \
    && cd /tmp/librdkafka \
    && ./configure \
    && make \
    && make install \
    && rm -rf /tmp/librdkafka

RUN pecl channel-update pecl.php.net \
    && pecl install mongodb \
    && docker-php-ext-enable mongodb \
    && rm -rf /mongodb

RUN pecl channel-update pecl.php.net \
    && pecl install rdkafka-$EXT_RDKAFKA_VERSION \
    && docker-php-ext-enable rdkafka \
    && rm -rf /librdkafka \
    && apk del $BUILD_DEPS