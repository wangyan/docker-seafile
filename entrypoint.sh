#!/bin/bash
set -x

if [ ! -d "/opt/seafile/installed/" ]; then
    /usr/bin/seafile-download
fi

if [ ! -f "/opt/seafile/conf/seahub_settings.pyc" ]; then
    if [ -z "$MYSQL_ENV_MYSQL_ROOT_PASSWORD" ]; then
        [ -z "$MYSQL_ROOT_PASSWORD" ] && MYSQL_ROOT_PASSWORD=123456
        /usr/bin/mysql-setup MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
        /usr/bin/seafile-setup-mysql
    else
        /usr/bin/seafile-setup
    fi
fi

if [ ! -f "/etc/nginx/conf.d/seafile.conf" ]; then
    /usr/bin/seafile-nginx
fi

if [ -f "/etc/init.d/mysql" ]; then
    /etc/init.d/mysql stop &>/dev/null
    /etc/init.d/mysql start
fi

if [ -f "/etc/init.d/seafile" ]; then
    chown root:root /opt/seafile -R
    /etc/init.d/seafile stop &>/dev/null
    /etc/init.d/seafile start
fi

if [ -f "/etc/init.d/nginx" ]; then
    /etc/init.d/nginx stop &>/dev/null
    /etc/init.d/nginx start
fi

exec "$@"