#!/bin/bash
set -x
# -------------------------------------------
# Vars Don't touch these unless you really know what you are doing!
# -------------------------------------------
SEAFILE_VERSION=$(ls /opt/seafile/installed/ | awk -F_ '{print $2}')
INSTALLPATH=/opt/seafile/seafile-server-${SEAFILE_VERSION}
TOPDIR=$(dirname "${INSTALLPATH}")
##--Create conf/ccnet.conf--##
CCNET_INIT=${INSTALLPATH}/seafile/bin/ccnet-init
DEFAULT_CONF_DIR=${TOPDIR}/conf
#--Generate conf/seahub_settings.py--##
SEAHUB_SECRET_KEYGEN=${INSTALLPATH}/seahub/tools/secret_key_generator.py
DEST_SETTINGS_PY=${TOPDIR}/conf/seahub_settings.py
##--Create ccnet/seafile.ini--##
SEAFILE_DATA_DIR=${TOPDIR}/seafile-data
DEFAULT_CCNET_CONF_DIR=${TOPDIR}/ccnet
##--Create conf/seafile.conf--##
SEAF_SERVER_INIT=${INSTALLPATH}/seafile/bin/seaf-server-init
FILESERVER_PORT=8082
#--prepare avatar directory--##
ORIG_AVATAR_DIR=${INSTALLPATH}/seahub/media/avatars
DEST_AVATAR_DIR=${TOPDIR}/seahub-data/avatars
MEDIA_DIR=${INSTALLPATH}/seahub/media
#--Create symlink for current server version--##
SEAFILE_SERVER_SYMLINK=${TOPDIR}/seafile-server-latest
# copy user manuals to library template
LIBRARY_TEMPLATE_DIR=${SEAFILE_DATA_DIR}/library-template
SRC_DOCS_DIR=${INSTALLPATH}/seafile/docs/

# -------------------------------------------
# Seafile DB
# -------------------------------------------

SEAFILE_SQL_USER=$(mysql -hmysql -p$MYSQL_PORT_3306_TCP_PORT -uroot -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -sse "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = 'seafile')")

if [ $SEAFILE_SQL_USER = 1 ];then
    mysql -hmysql -p$MYSQL_PORT_3306_TCP_PORT -uroot -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD -sse "DROP USER 'seafile'@'%'"
fi

[ -z "$SQLSEAFILEPW" ] && SQLSEAFILEPW=$(pwgen)

cat >/tmp/create_tables.sql<<-EOF
DROP DATABASE IF EXISTS seafile_ccnet;
DROP DATABASE IF EXISTS seafile_db;
DROP DATABASE IF EXISTS seafile_seahub;
CREATE DATABASE IF NOT EXISTS seafile_ccnet character set = 'utf8';
CREATE DATABASE IF NOT EXISTS seafile_db character set = 'utf8';
CREATE DATABASE IF NOT EXISTS seafile_seahub character set = 'utf8';
CREATE USER 'seafile'@'%' IDENTIFIED BY '$SQLSEAFILEPW';
GRANT ALL PRIVILEGES ON seafile_ccnet.* TO 'seafile'@'%';
GRANT ALL PRIVILEGES ON seafile_db.* TO 'seafile'@'%';
GRANT ALL PRIVILEGES ON seafile_seahub.* TO 'seafile'@'%';
EOF

mysql -hmysql -p$MYSQL_PORT_3306_TCP_PORT -uroot -p$MYSQL_ENV_MYSQL_ROOT_PASSWORD <<EOF
source /tmp/create_tables.sql;
use seafile_seahub;
source ${INSTALLPATH}/seahub/sql/mysql.sql;
EOF

# -------------------------------------------
# Create conf/ccnet.conf
# -------------------------------------------
[ -z $SERVER_NAME ] && SERVER_NAME=$(hostname -s)

[ -z $IP_OR_DOMAIN ] && IP_OR_DOMAIN=$(hostname -i)

export SEAFILE_LD_LIBRARY_PATH=${INSTALLPATH}/seafile/lib/:${INSTALLPATH}/seafile/lib64:${LD_LIBRARY_PATH}
LD_LIBRARY_PATH=$SEAFILE_LD_LIBRARY_PATH "${CCNET_INIT}" -c "${DEFAULT_CONF_DIR}" \
  --name "${SERVER_NAME}" --host "${IP_OR_DOMAIN}"

eval "sed -i 's/^SERVICE_URL.*/SERVICE_URL = http:\/\/${IP_OR_DOMAIN}/' ${DEFAULT_CONF_DIR}/ccnet.conf"

# -------------------------------------------
# Configuring conf/ccnet.conf
# -------------------------------------------
cat >> ${DEFAULT_CONF_DIR}/ccnet.conf <<EOF

[Database]
ENGINE = mysql
HOST = mysql
PORT = $MYSQL_PORT_3306_TCP_PORT
USER = seafile
PASSWD = $SQLSEAFILEPW
DB = seafile_ccnet
CONNECTION_CHARSET = utf8
EOF

# -------------------------------------------
# Create conf/seafdav.conf
# -------------------------------------------
cat > ${DEFAULT_CONF_DIR}/seafdav.conf <<EOF
[WEBDAV]
enabled = true
port = 8080
fastcgi = true
share_name = /seafdav
EOF

# -------------------------------------------
# generate conf/seahub_settings.py
# -------------------------------------------
key=$(python "${SEAHUB_SECRET_KEYGEN}")
echo "SECRET_KEY = \"${key}\"" > "${DEST_SETTINGS_PY}"

# -------------------------------------------
# Configuring conf/seahub_settings.py
# -------------------------------------------
cat >> ${DEST_SETTINGS_PY} <<EOF

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'seafile_seahub',
        'USER': 'seafile',
        'PASSWORD': '$SQLSEAFILEPW',
        'HOST': 'mysql',
        'PORT': $MYSQL_PORT_3306_TCP_PORT
    }
}

EMAIL_USE_TLS         = False
EMAIL_HOST            = 'smtp.exmail.qq.com'
EMAIL_HOST_USER       = 'noreply@wangyan.org'
EMAIL_HOST_PASSWORD   = 'Noreply123'
EMAIL_PORT            = '25'
DEFAULT_FROM_EMAIL    = EMAIL_HOST_USER
SERVER_EMAIL          = EMAIL_HOST_USER
EOF

# -------------------------------------------
# Create ccnet/seafile.ini
# -------------------------------------------
mkdir -p ${DEFAULT_CCNET_CONF_DIR}
mv ${DEFAULT_CONF_DIR}/mykey.peer ${DEFAULT_CCNET_CONF_DIR}
echo "${SEAFILE_DATA_DIR}" > "${DEFAULT_CCNET_CONF_DIR}/seafile.ini"

# -------------------------------------------
# Create conf/seafile.conf
# -------------------------------------------
LD_LIBRARY_PATH=$SEAFILE_LD_LIBRARY_PATH ${SEAF_SERVER_INIT} --seafile-dir "${DEFAULT_CONF_DIR}" \
  --fileserver-port ${FILESERVER_PORT}

# -------------------------------------------
# Configuring conf/seafile.conf
# -------------------------------------------
cat >> ${DEFAULT_CONF_DIR}/seafile.conf <<EOF

[database]
type = mysql
host = mysql
port = $MYSQL_PORT_3306_TCP_PORT
user = seafile
password = $SQLSEAFILEPW
db_name = seafile_db
connection_charset = utf8

[general]
enable_syslog = true
EOF

# -------------------------------------------
# prepare avatar directory
# -------------------------------------------
mkdir -p "${TOPDIR}/seahub-data"
mv "${ORIG_AVATAR_DIR}" "${DEST_AVATAR_DIR}"
ln -s ${DEST_AVATAR_DIR} ${MEDIA_DIR}

# -------------------------------------------
# create logs directory
# -------------------------------------------
mkdir -p "${TOPDIR}/logs"

# -------------------------------------------
# Create symlink for current server version
# -------------------------------------------
ln -s $(basename ${INSTALLPATH}) ${SEAFILE_SERVER_SYMLINK}

# -------------------------------------------
# copy user manuals to library template
# -------------------------------------------
mkdir -p ${LIBRARY_TEMPLATE_DIR}
cp -f ${SRC_DOCS_DIR}/*.doc ${LIBRARY_TEMPLATE_DIR}

# -------------------------------------------
# Backup check_init_admin.py befor applying changes
# -------------------------------------------
cp ${INSTALLPATH}/check_init_admin.py ${INSTALLPATH}/check_init_admin.py.backup

# -------------------------------------------
# Set admin credentials in check_init_admin.py
# -------------------------------------------
if [ -z $SEAFILE_ADMIN ]; then
  SEAFILE_ADMIN=admin@seafile.com
fi

if [ -z $SEAFILE_ADMIN_PW ]; then
  SEAFILE_ADMIN_PW=$(pwgen)
fi

eval "sed -i 's/= ask_admin_email()/= \"${SEAFILE_ADMIN}\"/' ${INSTALLPATH}/check_init_admin.py"
eval "sed -i 's/= ask_admin_password()/= \"${SEAFILE_ADMIN_PW}\"/' ${INSTALLPATH}/check_init_admin.py"

# -------------------------------------------
# Start and stop Seafile eco system. This generates the initial admin user.
# -------------------------------------------
# Fix permissions
chmod 0600 "$DEST_SETTINGS_PY"
chmod 0700 "$DEFAULT_CONF_DIR" "$DEFAULT_CCNET_CONF_DIR" "$SEAFILE_DATA_DIR"
${TOPDIR}/seafile-server-${SEAFILE_VERSION}/seafile.sh restart
${TOPDIR}/seafile-server-${SEAFILE_VERSION}/seahub.sh start

# -------------------------------------------
# Fix permissions
# -------------------------------------------
useradd -rU seafile
chown seafile.seafile -R /opt/seafile/

# -------------------------------------------
# create /etc/init.d/seafile-server
# -------------------------------------------
cat > /etc/init.d/seafile<<'EOF'
#!/bin/bash

seafile_dir=/opt/seafile
script_path=${seafile_dir}/seafile-server-latest
seafile_init_log=${seafile_dir}/logs/seafile.init.log
seahub_init_log=${seafile_dir}/logs/seahub.init.log
fastcgi=true
fastcgi_port=8000

echo -e "\n \n About to perform $1 for seafile at `date -Iseconds` \n " >> ${seafile_init_log}
echo -e "\n \n About to perform $1 for seahub at `date -Iseconds` \n " >> ${seahub_init_log}

case "$1" in
    start)
        ${user} ${script_path}/seafile.sh ${1} >> ${seafile_init_log}
        if [ $fastcgi = true ];
        then
            ${script_path}/seahub.sh ${1}-fastcgi ${fastcgi_port} >> ${seahub_init_log}
        else
            ${script_path}/seahub.sh ${1} >> ${seahub_init_log}
        fi
    ;;
    restart)
        ${script_path}/seafile.sh ${1} >> ${seafile_init_log}
        if [ $fastcgi = true ];
        then
            ${script_path}/seahub.sh ${1}-fastcgi ${fastcgi_port} >> ${seahub_init_log}
        else
            ${script_path}/seahub.sh ${1} >> ${seahub_init_log}
        fi
    ;;
    stop)
        ${script_path}/seahub.sh ${1} >> ${seahub_init_log}
        ${script_path}/seafile.sh ${1} >> ${seafile_init_log}
    ;;
    *)
        echo "Usage: /etc/init.d/seafile {start|stop|restart}"
        exit 1
    ;;
esac
EOF

chmod +x /etc/init.d/seafile
update-rc.d seafile defaults >/dev/null 2>&1

useradd -rU seafile
chown seafile.seafile -R /opt/seafile/

/etc/init.d/seafile restart