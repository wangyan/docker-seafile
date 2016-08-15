#!/bin/bash
set -x

if [ ! -d "/opt/seafile/installed/" ]; then
  /usr/bin/seafile-download
fi

if [ ! -f "/opt/seafile/conf/seahub_settings.pyc" ]; then
  /usr/bin/seafile-setup
fi

if [ ! -f "/etc/nginx/sites-available/seafile.conf " ]; then
  /usr/bin/seafile-nginx
fi

exec "$@"