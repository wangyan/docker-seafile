# Seafile-Docker

Seafile Docker image based on Ubuntu 16.04 LTS

Source Code:  <https://github.com/wangyan/docker-seafile>

## Features

- Always use the newest version of seafile
- Configurable to run with MySQL
- Support `Nginx SSl`,`WebDAV` features
- Auto-setup at initial run.

## Install Docker

**Debian**

```shell
apt-get update && apt-get -y install curl && \
curl -sSL https://get.docker.com/ | sh
```

 **CentOS**

```shel
curl -sSL https://get.docker.com/ | sh
```

## Install MySQL

> `MYSQL_ROOT_PASSWORD`  MySQL root password

```shell
docker run --name mysql \
-v /var/lib/mysql:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=123456 \
-p 3306:3306 \
-d mysql:latest
```

## Quickstart

- `IP_OR_DOMAIN`  IP  Address or Domain
- `SEAFILE_ADMIN`  E-mail address of the Seafile admin
- `SEAFILE_ADMIN_PW`   Password of the Seafile admin
- `SQLSEAFILEPW` Password for Seafile MySQL User

> **Note** By default, you must open 8082 port

```shell
docker run --name seafile \
--link mysql:mysql \
-p 8082:8082 \
-p 80:80 \
-p 443:443 \
-e IP_OR_DOMAIN=cloud.wangyan.org \
-e SEAFILE_ADMIN=info@wangyan.org \
-e SEAFILE_ADMIN_PW=123456 \
-e SQLSEAFILEPW=123456 \
-v /home/seafile:/opt/seafile \
-d myidwy/seafile
```

```shell
docker logs -f seafile // logs...
```

## Tools

```shell
curl --fail -L -O https://github.com/phusion/baseimage-docker/archive/master.tar.gz && \
tar xzf master.tar.gz && \
./baseimage-docker-master/install-tools.sh
```

```shell
docker-bash seafile
```