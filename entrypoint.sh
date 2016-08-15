#!/bin/bash
set -x

if [ ! -d "/opt/seafile/installed/" ]; then
  /usr/local/bin/download-seafile
fi

if [ ! -f "/opt/seafile/conf/seahub_settings.pyc" ]; then
  /usr/local/bin/setup-seafile
fi

if [ ! -f "/etc/nginx/nginx.conf" ]; then
  /usr/local/bin/setup-nginx
fi

exec "$@"