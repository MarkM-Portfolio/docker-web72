##################################################
#            PHP-FPM INSTALLATION
##################################################
# official image: https://hub.docker.com/_/php
# PHP FPM Dockerfile, based from official PHP image
# running on alpine(3.4) operating system
FROM php:7.2-fpm-alpine as php
RUN ln -s /usr/local/bin/php /usr/local/bin/php72

# install/copy docker php extensions installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/

# install php extensions
RUN install-php-extensions \
    calendar \
    exif \
    gd gettext \
    imap intl \
    mcrypt mongodb mysqli \
    opcache \
    pcntl pdo_mysql \
    shmop sockets soap snmp sysvmsg sysvsem sysvshm \
    wddx \
    xdebug xsl \
    zip  \
    ddtrace \
    datadog-profiling \
    ddappsec \
    && rm -rf /tmp/* || true

# v 0.0.8:install sodium, then cleanup the files
RUN apk add --no-cache autoconf g++ make && pecl install libsodium-1.0.7 \
    && /usr/local/bin/docker-php-ext-enable libsodium \
    && /usr/local/bin/docker-php-ext-enable pdo_mysql \
    && apk del autoconf g++ make \
    && rm -rf /tmp/* || true

##################################################
#            COMPOSER INSTALLATION
##################################################
# install package dependencies for composer
RUN apk add --no-cache --update git vim unzip nano bash zsh ngrep libexecinfo

# retrieve composer installer
RUN cd ~ && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

# install composer globally
RUN cd ~ && php composer-setup.php --install-dir=/usr/local/bin --filename=composer --version=1.10.19

# install composer plugin for parallel installs to speed up composer installs
# It will reduce the composer install/update time possibly significantly.

# set github personal token for composer
RUN composer config -g github-oauth.github.com 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

##################################################
#            APPLICATION
##################################################
# modify user and group and set id "1000" (www-data is nginx)
RUN apk add shadow && usermod -u 1200 www-data && groupmod -g 1200 www-data

# create the application directory
RUN mkdir /var/www/public_html

# copy project from host to the container
COPY . /var/www/public_html

# change ownership of directory and files
RUN chown -R root:www-data /var/www/public_html

# set working directory
WORKDIR /var/www/public_html

##################################################
#            NGINX INSTALLATION
##################################################
# official image: https://hub.docker.com/_/nginx/
# Nginx installation is based on official image: https://hub.docker.com/_/nginx/
ENV NGINX_VERSION 1.20.0
RUN GPG_KEYS=B0F4253373F8F6F510D42178520A9993A1C052F8 \
    && CONFIG="\
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_addition_module \
        --with-http_sub_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_mp4_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_random_index_module \
        --with-http_secure_link_module \
        --with-http_stub_status_module \
        --with-http_auth_request_module \
        --with-http_xslt_module=dynamic \
        --with-http_image_filter_module=dynamic \
        --with-http_geoip_module=dynamic \
        --with-http_perl_module=dynamic \
        --with-threads \
        --with-stream \
        --with-stream_ssl_module \
        --with-stream_realip_module \
        --with-stream_geoip_module=dynamic \
        --with-http_slice_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-file-aio \
        --with-http_v2_module \
        --with-ipv6 \
    " \
    && addgroup -S nginx \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx \
    && apk add --no-cache --virtual .build-deps \
        curl \
        gcc \
        gd-dev \
        geoip-dev \
        gnupg \
        libc-dev \
        libressl-dev \
        libxslt-dev \
        linux-headers \
        make \
        pcre-dev \
        perl-dev \
        zlib-dev \
    && curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
    && curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc  -o nginx.tar.gz.asc \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEYS" \
    && gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
    && pkill -9 gpg-agent \
    && pkill -9 dirmngr \
    && rm -r "$GNUPGHOME" nginx.tar.gz.asc || true \
    && mkdir -p /usr/src \
    && tar -zxC /usr/src -f nginx.tar.gz \
    && rm nginx.tar.gz \
    && cd /usr/src/nginx-$NGINX_VERSION \
    && ./configure $CONFIG --with-debug \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && mv objs/nginx objs/nginx-debug \
    && mv objs/ngx_http_xslt_filter_module.so objs/ngx_http_xslt_filter_module-debug.so \
    && mv objs/ngx_http_image_filter_module.so objs/ngx_http_image_filter_module-debug.so \
    && mv objs/ngx_http_geoip_module.so objs/ngx_http_geoip_module-debug.so \
    && mv objs/ngx_http_perl_module.so objs/ngx_http_perl_module-debug.so \
    && mv objs/ngx_stream_geoip_module.so objs/ngx_stream_geoip_module-debug.so \
    && ./configure $CONFIG \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && rm -rf /etc/nginx/html/ \
    && mkdir /etc/nginx/conf.d/ \
    && mkdir -p /var/www/public_html/ \
    && install -m644 html/index.html /var/www/public_html/ \
    && install -m644 html/50x.html /var/www/public_html/ \
    && install -m755 objs/nginx-debug /usr/sbin/nginx-debug \
    && install -m755 objs/ngx_http_xslt_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_xslt_filter_module-debug.so \
    && install -m755 objs/ngx_http_image_filter_module-debug.so /usr/lib/nginx/modules/ngx_http_image_filter_module-debug.so \
    && install -m755 objs/ngx_http_geoip_module-debug.so /usr/lib/nginx/modules/ngx_http_geoip_module-debug.so \
    && install -m755 objs/ngx_http_perl_module-debug.so /usr/lib/nginx/modules/ngx_http_perl_module-debug.so \
    && install -m755 objs/ngx_stream_geoip_module-debug.so /usr/lib/nginx/modules/ngx_stream_geoip_module-debug.so \
    && ln -s ../../usr/lib/nginx/modules /etc/nginx/modules \
    && strip /usr/sbin/nginx* \
    && strip /usr/lib/nginx/modules/*.so \
    && rm -rf /usr/src/nginx-$NGINX_VERSION \
    \
    # Bring in gettext so we can get `envsubst`, then throw
    # the rest away. To do this, we need to install `gettext`
    # then move `envsubst` out of the way so `gettext` can
    # be deleted completely, then move `envsubst` back.
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    \
    && runDeps="$( \
        scanelf --needed --nobanner /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache --virtual .nginx-rundeps $runDeps \
    && apk del .build-deps \
    && apk del .gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
    \
    # forward request and error logs to docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

##################################################
#            NODEJS INSTALLATION
##################################################
# install nodejs
RUN apk add --no-cache --update nodejs nodejs-npm && npm install --global gulp-cli \
    && npm install --global gulp-cli

##################################################
#            SUPERVISORD INSTALLATION
##################################################
# It monitor processes, run them and ensure they are all running
RUN apk --no-cache add supervisor
COPY docker/stop-supervisor.sh /stop-supervisor.sh
RUN chmod +x /stop-supervisor.sh
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/nginx.vh.default.conf /etc/nginx/conf.d/default.conf
COPY docker/php.ini /usr/local/etc/php/conf.d/custom.ini
COPY docker/php-fpm.ini /usr/local/etc/php-fpm.d/docker.conf
COPY docker/phpinfo.php /var/www/public_html/_php_.php

COPY VERSION /VERSION

EXPOSE 80 443

ENTRYPOINT ["supervisord", "--configuration", "/etc/supervisord.conf"]
