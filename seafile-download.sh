#!/bin/bash
set -x
cd /opt/seafile

if [ "$APT_MIRRORS" = "aliyun" ];then
    sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list
fi

arch=$(uname -m | sed s/"_"/"-"/g)
regexp="http(s?):\/\/[^ \"\(\)\<\>]*seafile-server_[\d\.\_]*$arch.tar.gz"

which wget > /dev/null
wget=$?
which curl > /dev/null
curl=$?
if [ $wget -eq 0 ]; then
    addr=$(wget -c -t 10 -T 120 https://www.seafile.com/download/ -O - | grep -o -P "$regexp" | head -1)
    wget -q -c -t 10 -T 120 $addr
elif [ $curl -eq 0 ]; then
    addr=$(curl -C - -Ls https://www.seafile.com/download/ | grep -o -P "$regexp" | head -1)
    curl -Ls -C - -O $addr 
else
    echo "Neither curl nor wget found. Exiting."
    exit 1
fi

# figure out what directory the tarball is going to create
file=$( echo $addr | awk -F/ '{ print $NF }' )

# test that we got something
if [ ! -z $file -a -f $file ]; then
    dir=$( tar tvzf $file 2>/dev/null | head -n 1 | awk '{ print $NF }' | sed -e 's!/!!g')
    tar xzf $file

    # mkdir only if we don't already have one
    [ ! -d installed ] && mkdir installed

    # move the tarball only if we created the directory
    [ -d $dir ] && mv seafile-server_* installed
else
    echo "Seafile install file not downloaded. Exiting."
    exit 1
fi