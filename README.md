# Seafile-Docker

> 请优先使用 2.0版，1.0版基于 `Ubuntu 14.04` 构建，2.0是基于 `Ubuntu 16.04` 构建。

基于 `Ubuntu 14.04` 构建，一键自动安装最新版的 `Seafile`，并自动完成设置，使用外部`MySQL`数据库，支持 `Nginx SSL` 访问，默认开启 `WebDAV` 功能。了解更多信息，请访问`Seafile` 官网。<https://www.seafile.com>

## 一、安装 Docker

关于Docker 更多信息，请访问其官网。<https://docs.docker.com>

**debian**

```shell
apt-get update && apt-get -y install curl && \
curl -sSL https://get.daocloud.io/docker | sh \
update-rc.d -f docker defaults && service docker start
```

 **CentOS**

```shel
yum update && curl -sSL https://get.docker.com/ | sh && \
systemctl enable docker.service && systemctl start docker.service
```

## 二、安装 MySQL 数据库

> 注意将`123456`换成你的MySQL Root密码

```shell
docker run --name mysql \
-v /var/lib/mysql:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=123456 \
-p 3306:3306 \
-d mysql:latest
```

## 三、安装 phpMyAdmin (可选)

```shell
docker run --name phpmyadmin \
--link mysql:mysql \
-p 10086:80 \
-d registry.git.dmfy.gov.cn/wangyan/docker-phpmyadmin:latest
```

## 四、安装 Seafile

- `IP_OR_DOMAIN` 服务器IP或者域名
- `SEAFILE_ADMIN` 创建 Seafile 管理员账号
- `SEAFILE_ADMIN_PW`  Seafile 管理员密码
- `SQLSEAFILEPW` Seafile 数据库密码

> 注意：如果有防火墙，请务必开放8082端口，用于客户端同步。

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
-d registry.git.dmfy.gov.cn/wangyan/docker-seafile
```

```shell
docker logs -f seafile //查看安装进度
```

## 五、常见操作

### 5.1 进入容器

首先，安装个小工具

```shell
curl --fail -L -O https://github.com/phusion/baseimage-docker/archive/master.tar.gz && \
tar xzf master.tar.gz && \
./baseimage-docker-master/install-tools.sh
```

然后，进入容器

```shell
docker-bash seafile
```

**配置文件路径**

- `nginx 配置文件` /etc/nginx/conf.d/seafile.conf
- `seafile 配置文件` /opt/seafile/conf/

### 5.2 重启操作

重启 nginx（nginx 修改配置文件后，需要重启）

```shell
sv reload nginx
```

重启 seafile 

```shell
/etc/init.d/seafile restart
```

## 六、系统设置(可选)

### 6.1. 解决Debian本地化问题

```shell
apt-get update && apt-get install -y language-pack-zh-hans-base
```

```shell
cat >/etc/default/locale<<-EOF
LANG=zh_CN.UTF-8
LANGUAGE=zh_CN.UTF-8
LC_ALL=zh_CN.UTF-8
EOF
```

```shell
locale-gen "zh_CN.UTF-8" && dpkg-reconfigure locales
```

### 6.2.设置中国时区

**Debbian** 

```shell
rm -rf /etc/localtime && \
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
echo "Asia/Shanghai" > /etc/timezone && \
apt-get -y install ntpdate && ntpdate -d cn.pool.ntp.org
```

**CentOS 7** 

via <http://blog.wangyan.org/linux-centos-timedatectl>

```shell
imedatectl set-timezone Asia/Shanghai
timedatectl set-ntp yes 
```

### 6.3.安装 FUSE 扩展

```shell
mkdir -p /data/seafile-fuse && \
/opt/seafile/seafile-server-latest/seaf-fuse.sh start /data/seafile-fuse //启动
./seaf-fuse.sh stop //停止
```

## 七、了解更多

关于`Seafile`更多信息，请访问其官网。<http://manual.seafile.com/>

更多使用帮助请阅读`wiki`，其他问题欢迎在`issues`中反馈。