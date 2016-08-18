#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH TERM=xterm

if [ $(id -u) != "0" ]; then
  printf "Error: You must be root to run this script!"
  exit 1
fi

if [ "$(which mysqld)" != '' ];then
	echo >&2 'MySQL is already installed!'
	exit 1
fi

clear
echo "#############################################################"
echo "# MySQL Auto Install Script"
echo "# Env: Debian/Ubuntu"
echo "# Intro: http://wangyan.org/"
echo "#"
echo "# Copyright (c) 2016, WangYan <i@wangyan.org>"
echo "# All rights reserved."
echo "# Distributed under the GNU General Public License, version 3.0."
echo "#"
echo "#############################################################"
echo

apt-get update -y && \
apt-get install -y perl pwgen --no-install-recommends

if [ "${1:5:1}" != '_' ]; then
	echo
	echo "Please input the root password of mysql:"
	read -p "(Default password is random characters):" MYSQL_ROOT_PASSWORD
	if [ -z $MYSQL_ROOT_PASSWORD ]; then
	  MYSQL_ROOT_PASSWORD="$(pwgen -1 16)"
	fi
	echo "---------------------------"
	echo "MYSQL_ROOT_PASSWORD = $MYSQL_ROOT_PASSWORD"
	echo "---------------------------"
	echo
fi

if [ "${1:5:1}" = '_' ]; then
	export "$@"
	if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
		echo
		echo >&2 'Did you forget to add PASSWORD=... ?'
		exit 1
	fi
fi

echo 
echo "---------------------------"
echo "-- MySQL ROOT PASSWORD:"
echo "-- $MYSQL_ROOT_PASSWORD"
echo "---------------------------"
echo

# Setup MySQL
MYSQL_MAJOR=5.7
MYSQL_VERSION=5.7.14-1ubuntu16.04

echo "deb http://repo.mysql.com/apt/ubuntu/ xenial mysql-${MYSQL_MAJOR}" >> /etc/apt/sources.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5


{ \
	echo mysql-community-server mysql-community-server/data-dir select ''; \
	echo mysql-community-server mysql-community-server/root-pass password ''; \
	echo mysql-community-server mysql-community-server/re-root-pass password ''; \
	echo mysql-community-server mysql-community-server/remove-test-db select false; \
} | debconf-set-selections && \
	apt-get update && apt-get install -y mysql-server="${MYSQL_VERSION}" && \
	rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld && \
	chown -R mysql:mysql /var/lib/mysql /var/run/mysqld && \
	chmod 777 /var/run/mysqld

# MySQL Config

sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf && \
echo 'skip-host-cache\nskip-name-resolve' | awk '{ print } $1 == "[mysqld]" && c == 0 { c = 1; system("cat") }' /etc/mysql/my.cnf > /tmp/my.cnf && mv /tmp/my.cnf /etc/mysql/my.cnf

DATADIR="$(mysqld --verbose --help 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')"

if [ ! -d "$DATADIR/mysql" ]; then

	mkdir -p "$DATADIR"
	chown -R mysql:mysql "$DATADIR"

	echo 
	echo 'Initializing database'
	mysqld --initialize-insecure --user=mysql
	echo 'Database initialized'

	mysqld --user=mysql --skip-networking --explicit_defaults_for_timestamp &
	pid="$!"

	mysql=( mysql --protocol=socket -uroot )

	for i in {30..0}; do
		if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
			break
		fi
		echo 'MySQL init process in progress...'
		sleep 1
	done

	if [ "$i" = 0 ]; then
		echo >&2 'MySQL init process failed.'
		apt-get -y remove mysql-server="${MYSQL_VERSION}"
		apt -y autoremove
		rm -rf /var/lib/mysql /etc/mysql
		exit 1
	fi

	"${mysql[@]}" <<-EOSQL
		-- What's done in this file shouldn't be replicated
		--  or products like mysql-fabric won't work
		SET @@SESSION.SQL_LOG_BIN=0;
		DELETE FROM mysql.user ;
		CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
		GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
		DROP DATABASE IF EXISTS test ;
		FLUSH PRIVILEGES ;
	EOSQL

	if [ ! -z "$MYSQL_ROOT_PASSWORD" ]; then
		mysql+=( -p"${MYSQL_ROOT_PASSWORD}" )
	fi

	if [ "$MYSQL_DATABASE" ]; then
		echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" | "${mysql[@]}"
		mysql+=( "$MYSQL_DATABASE" )
	fi

	if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
		echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;" | "${mysql[@]}"
		if [ "$MYSQL_DATABASE" ]; then
			echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%' ;" | "${mysql[@]}"
		fi
		echo 'FLUSH PRIVILEGES ;' | "${mysql[@]}"
	fi

	if [ ! -z "$MYSQL_ONETIME_PASSWORD" ]; then
		"${mysql[@]}" <<-EOSQL
			ALTER USER 'root'@'%' PASSWORD EXPIRE;
		EOSQL
	fi

	if ! kill -s TERM "$pid" || ! wait "$pid"; then
		echo >&2 'MySQL init process failed.'
		exit 1
	fi

	echo
	echo 'MySQL init process done. Ready for start up.'
	echo
fi

/etc/init.d/mysql start