FROM alpine:edge
MAINTAINER Sérgio Leal <hello@wherd.name>

# Timezone
ENV TIMEZONE Europe/Lisbon

# Add repositories
RUN echo "@community http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories
RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# Upgrade system
RUN apk update && apk upgrade

# Install mysql, apache and php and php extensions
RUN apk add --no-cache      \
    apache2                 \
    curl                    \
    git                     \
    mysql                   \
    mysql-client            \
    memcached               \
    pwgen                   \
    tzdata                  \
    openssl                 \
    wget                    \
    php7-apache2            \
    php7-bcmath             \
    php7-bz2                \
    php7-ctype              \
    php7-curl               \
    php7-dom                \
    php7-gd                 \
    php7-gmp                \
    php7-iconv              \
    php7-imap               \
    php7-intl               \
    php7-json               \
    php7-mcrypt             \
    php7-memcached@testing  \
    php7-mysqli             \
    php7-opcache            \
    php7-openssl            \
    php7-pdo                \
    php7-pdo_mysql          \
    php7-phar               \
    php7-xdebug             \
    php7-xml                \
    php7-xmlrpc             \
    php7-zip                \
    php7-zlib

RUN ln -s /usr/bin/php7 /usr/bin/php

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
 
# Configure timezone, mysql, apache
RUN cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone

RUN mkdir -p /run/mysqld && chown -R mysql:mysql /run/mysqld /var/lib/mysql && \
    mysql_install_db --user=root --verbose=1 --basedir=/usr --datadir=/var/lib/mysql --rpm > /dev/null

RUN mkdir -p /run/apache2                   && \
    chown -R apache:apache /run/apache2     && \
    mkdir -p /var/www/localhost/htdocs      && \
    chown -R apache:apache /var/www/localhost/htdocs/

RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/httpd.conf                        && \
    sed -i 's/#LoadModule rewrite/LoadModule rewrite/' /etc/apache2/httpd.conf                      && \
    sed -i 's/ServerName www.example.com:80/ServerName localhost:80/' /etc/apache2/httpd.conf       && \
    sed -i '/skip-external-locking/a log_error = \/var\/lib\/mysql\/error.log' /etc/mysql/my.cnf    && \
    sed -i '/skip-external-locking/a general_log = ON' /etc/mysql/my.cnf                            && \
    sed -i '/skip-external-locking/a general_log_file = \/var\/lib\/mysql\/query.log' /etc/mysql/my.cnf

# Configure xdebug
RUN echo "zend_extension=xdebug.so" > /etc/php7/conf.d/xdebug.ini                   && \
    echo -e "\n[XDEBUG]"  >> /etc/php7/conf.d/xdebug.ini                            && \
    echo "xdebug.remote_enable=1" >> /etc/php7/conf.d/xdebug.ini                    && \
    echo "xdebug.remote_connect_back=1" >> /etc/php7/conf.d/xdebug.ini              && \
    echo "xdebug.idekey=PHPDEBUG" >> /etc/php7/conf.d/xdebug.ini                    && \
    echo "xdebug.remote_log=\"/tmp/xdebug.log\"" >> /etc/php7/conf.d/xdebug.ini

# Start apache
RUN echo "#!/bin/sh" > /start.sh                                                                && \
    echo "mkdir -p /var/www/localhost/htdocs" >> /start.sh                                      && \
    echo "chown -R apache:apache /var/www/localhost/htdocs" >> /start.sh                        && \
    echo "httpd" >> /start.sh                                                                   && \
    echo "nohup memcached -u apache > /dev/null 2>&1 &" >> /start.sh                                      && \
    echo "nohup mysqld --user=root --datadir=/var/lib/mysql > /dev/null 2>&1 &" >> /start.sh    && \
    echo "tail -f /var/log/apache2/access.log" >> /start.sh                                     && \
    chmod u+x /start.sh

WORKDIR /var/www/localhost

EXPOSE 80 443 3306 11211

ENTRYPOINT ["/start.sh"]
