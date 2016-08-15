FROM phusion/baseimage:0.9.18
MAINTAINER WangYan <i@wangyan.org>

RUN mkdir -p /opt/seafile
WORKDIR /opt/seafile

RUN curl http://mirrors.163.com/.help/sources.list.trusty -o sources.list && \
    mv -f ./sources.list /etc/apt/sources.list && \
    apt-get update && \
    apt-get -y install pwgen mysql-client \
    python2.7 libpython2.7 python-setuptools python-imaging python-ldap python-mysqldb python-memcache

ADD ./download-seafile.sh /usr/local/bin/download-seafile
ADD ./setup-nginx.sh /usr/local/bin/setup-nginx
ADD ./setup-seafile.sh /usr/local/bin/setup-seafile
ADD ./entrypoint.sh /entrypoint.sh

RUN chmod +x /usr/local/bin/download-seafile /usr/local/bin/setup-nginx /usr/local/bin/setup-seafile /entrypoint.sh
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/sbin/my_init"]