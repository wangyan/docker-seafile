FROM phusion/baseimage:0.9.19
MAINTAINER WangYan <i@wangyan.org>

RUN mkdir -p /opt/seafile
WORKDIR /opt/seafile

RUN apt-get -y update && apt-get -y install wget \
    sudo pwgen net-tools mysql-client libmysqlclient-dev \
    python2.7 libpython2.7 python-setuptools python-imaging \
    python-ldap python-mysqldb python-memcache python-urllib3

# Seafile Config
ADD ./seafile-download.sh /usr/bin/seafile-download
ADD ./seafile-setup.sh /usr/bin/seafile-setup
ADD ./seafile-nginx.sh /usr/bin/seafile-nginx
ADD ./entrypoint.sh /entrypoint.sh

RUN chmod +x /usr/bin/seafile-download /usr/bin/seafile-setup \
            /usr/bin/seafile-nginx /entrypoint.sh

# Expose Ports
EXPOSE 8082
EXPOSE 80
EXPOSE 443

# APT Clean
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ./nginx_signing.key

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/sbin/my_init"]