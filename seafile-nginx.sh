#!/bin/bash
set -x
# -------------------------------------------
# NGINX
# -------------------------------------------
curl -O "http://nginx.org/keys/nginx_signing.key" && \
apt-key add nginx_signing.key && rm -f nginx_signing.key && \
echo "deb http://nginx.org/packages/ubuntu/ xenial nginx" >> /etc/apt/sources.list && \
echo "deb-src http://nginx.org/packages/ubuntu/ xenial nginx" >> /etc/apt/sources.list && \
apt-get update && apt-get install -y nginx

rm -f /etc/nginx/conf.d/*
mkdir -p /etc/nginx/ssl/

[ -z $IP_OR_DOMAIN ] && IP_OR_DOMAIN=$(hostname -i)

cat >/etc/nginx/conf.d/seafile.conf<<'EOF'
server {
    listen 80;
    server_name "IP_OR_DOMAIN";
   #rewrite ^ https://$http_host$request_uri? permanent;

    proxy_set_header X-Forwarded-For $remote_addr;

    location / {
        fastcgi_pass    127.0.0.1:8000;
        fastcgi_param   SCRIPT_FILENAME     $document_root$fastcgi_script_name;
        fastcgi_param   PATH_INFO           $fastcgi_script_name;

        fastcgi_param   SERVER_PROTOCOL     $server_protocol;
        fastcgi_param   QUERY_STRING        $query_string;
        fastcgi_param   REQUEST_METHOD      $request_method;
        fastcgi_param   CONTENT_TYPE        $content_type;
        fastcgi_param   CONTENT_LENGTH      $content_length;
        fastcgi_param   SERVER_ADDR         $server_addr;
        fastcgi_param   SERVER_PORT         $server_port;
        fastcgi_param   SERVER_NAME         $server_name;
        fastcgi_param   REMOTE_ADDR         $remote_addr;

        access_log      /var/log/nginx/seahub.access.log;
        error_log       /var/log/nginx/seahub.error.log;
        fastcgi_read_timeout 36000;
    }

    location /seafhttp {
        rewrite ^/seafhttp(.*)$ $1 break;
        proxy_pass http://127.0.0.1:8082;
        client_max_body_size 0;
        proxy_connect_timeout  36000s;
        proxy_read_timeout  36000s;
        proxy_send_timeout  36000s;
        send_timeout  36000s;
    }

    location /media {
        root /opt/seafile/seafile-server-latest/seahub;
    }
}

server {
  listen  443;
  server_name  "IP_OR_DOMAIN";
  
  ssl  on;
  ssl_certificate       /etc/nginx/ssl/Seafile-CA.pem;
  ssl_certificate_key  /etc/nginx/ssl/Seafile-KEY.pem;

  ssl_session_cache shared:SSL:1m;
  ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
  ssl_session_timeout  5m;

  ssl_ciphers  HIGH:!aNULL:!MD5;
  ssl_prefer_server_ciphers   on;

  location / {
    fastcgi_pass    127.0.0.1:8000;
    fastcgi_param   SCRIPT_FILENAME     $document_root$fastcgi_script_name;
    fastcgi_param   PATH_INFO           $fastcgi_script_name;
    fastcgi_param   SERVER_PROTOCOL     $server_protocol;
    fastcgi_param   QUERY_STRING        $query_string;
    fastcgi_param   REQUEST_METHOD      $request_method;
    fastcgi_param   CONTENT_TYPE        $content_type;
    fastcgi_param   CONTENT_LENGTH      $content_length;
    fastcgi_param   SERVER_ADDR         $server_addr;
    fastcgi_param   SERVER_PORT         $server_port;
    fastcgi_param   SERVER_NAME         $server_name;
    fastcgi_param   HTTPS               on;
    fastcgi_param   HTTP_SCHEME         https;

    access_log      /var/log/nginx/seahub.access.log;
    error_log       /var/log/nginx/seahub.error.log;
  }

  location /seafhttp {
    rewrite ^/seafhttp(.*)$ $1 break;
    proxy_pass http://127.0.0.1:8082;
    client_max_body_size 0;
    proxy_connect_timeout  36000s;
    proxy_read_timeout  36000s;
  }

  location /media {
    root /opt/seafile/seafile-server-latest/seahub;
  }

  location /seafdav {
    fastcgi_pass    127.0.0.1:8080;
    fastcgi_param   SCRIPT_FILENAME     $document_root$fastcgi_script_name;
    fastcgi_param   PATH_INFO           $fastcgi_script_name;
    fastcgi_param   SERVER_PROTOCOL     $server_protocol;
    fastcgi_param   QUERY_STRING        $query_string;
    fastcgi_param   REQUEST_METHOD      $request_method;
    fastcgi_param   CONTENT_TYPE        $content_type;
    fastcgi_param   CONTENT_LENGTH      $content_length;
    fastcgi_param   SERVER_ADDR         $server_addr;
    fastcgi_param   SERVER_PORT         $server_port;
    fastcgi_param   SERVER_NAME         $server_name;

    client_max_body_size 0;

    access_log      /var/log/nginx/seafdav.access.log;
    error_log       /var/log/nginx/seafdav.error.log;
  }
}
EOF

sed -i 's/IP_OR_DOMAIN/'$IP_OR_DOMAIN'/g' /etc/nginx/conf.d/seafile.conf

cat > /etc/nginx/ssl/Seafile-CA.pem <<'EOF'
-----BEGIN CERTIFICATE-----
MIIDNTCCAh2gAwIBAgIJAKhzGE4s6v2dMA0GCSqGSIb3DQEBCwUAMDExCzAJBgNV
BAYTAkNOMRAwDgYDVQQIDAdTZWFmaWxlMRAwDgYDVQQKDAdTZWFmaWxlMB4XDTE2
MDMwMjE0MDcwN1oXDTE5MDMwMjE0MDcwN1owMTELMAkGA1UEBhMCQ04xEDAOBgNV
BAgMB1NlYWZpbGUxEDAOBgNVBAoMB1NlYWZpbGUwggEiMA0GCSqGSIb3DQEBAQUA
A4IBDwAwggEKAoIBAQDYzI49Lkp9syjTwQaTbcK0PkuBNwuoQQHErrdPH0phmKtX
TjGSqCGyV1mHv1k/Dy17zEOFvSmLucnruk/wllDSIPDvnsdKkIplDMx9U755ckvA
W2IjywyajlttqO1l1bMyxemrevJ3kBRuMUTjiAq+PVx5CU+mg7XPdIUofFu8dWbA
e5MVZhOKdRwekj4PseRloLOzc4h9YdxiGqb6O9di3gMF4U4TLDT8exUxMbyUnWRv
N6NFTwasxObkc0ba+3OCI1IunWNQuk0N4JqWlQTUrQ3zKohd34D9VZfsAXiZpwEk
Axx+CJ1Y+yXO/IR4P5z5VIhnjG7z+w20wb6ISGW5AgMBAAGjUDBOMB0GA1UdDgQW
BBR5RcNzAiD1wpEcx/9KUCLPVSvMfjAfBgNVHSMEGDAWgBR5RcNzAiD1wpEcx/9K
UCLPVSvMfjAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQA+UtYj2m9s
Fz6oV5vpkr1kjPBv5OPG2E3IDq7OISOXETQYCJ7i/s8Wbx3LW2RA7Xfu4+LCtmri
wAyEc+uqBkhm+epXxdoLZrhTwVTTTOBxAekxriRZpe+ebwRYClFFcxYSBLrMPUDK
E7AE3hE7+R5VcYI0osIZNQdim3DtHtWHJt2fnZhRJdRicTplIm7K79hqrFl3hYte
2L0OPsqiXaG7SC3eO8Qp42w0BZzBBNzmPk1OYHooBDdGuhdCDzqIdFEQaXUm5/Dt
2j1lX3VBWmbkPt4GcB4GiOkYm5DP9PsUQZ4TH7TtwoYLoDLflPcsQ3kd/c+Bjrsr
DVSG1NHj8xA1
-----END CERTIFICATE-----
EOF

cat > /etc/nginx/ssl/Seafile-KEY.pem <<'EOF'
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA2MyOPS5KfbMo08EGk23CtD5LgTcLqEEBxK63Tx9KYZirV04x
kqghsldZh79ZPw8te8xDhb0pi7nJ67pP8JZQ0iDw757HSpCKZQzMfVO+eXJLwFti
I8sMmo5bbajtZdWzMsXpq3ryd5AUbjFE44gKvj1ceQlPpoO1z3SFKHxbvHVmwHuT
FWYTinUcHpI+D7HkZaCzs3OIfWHcYhqm+jvXYt4DBeFOEyw0/HsVMTG8lJ1kbzej
RU8GrMTm5HNG2vtzgiNSLp1jULpNDeCalpUE1K0N8yqIXd+A/VWX7AF4macBJAMc
fgidWPslzvyEeD+c+VSIZ4xu8/sNtMG+iEhluQIDAQABAoIBAGeT+1URm7dIdHYO
36RqKT7SEGLQuLoPLNgaHSwpJ/FO7nWMvzRxLYA2KWkoq2vsRW/DHHN197Zw8h60
aeLo/f4WjOX+tvpR6jzzC3PJIdSGHdjuEApHxWLGJrpSnfEsUywr0EMEP3mOFaS7
10zZv0A6ssaFA0/r114hLkk0eOOlVm1q1o445oQBYCIhW8j1P2enTOrdc7hz91U7
0BLN/9lRo1W23YCQsz9aMoUj7S3TBD1i7LVq5P28MI5N3GiqJQnvVHo9qE9ggAf+
hI4G1j6cI6JO5MyUeqjbhKDIjHeO1Do09Y01tM4eDC9FPF+5FSmDaOmNbF7IVIFz
Nba10V0CgYEA7ilDE0GRvYaouPLMT37c9oLBLgU4azRlhb0oVxIhXjyVP6e//rW/
6iu5S/x0UyEMW8naLbE7zijR0eQnkQa6sJlIRNlQSBhb2Fb4JYFDuh3N8ZBQDkoj
ZQkRhtzVZGdHhWfLutRBdj4zJ20h6hKYcsSMKkWqT+p7mCfUheqf58sCgYEA6Qms
x3k+TLP+Mdc+yFtFLu1sMcjuS7OFpgxje3zyl+Wj9ieFTRztwumyzOHptxwIQZrq
LSTiWWcJnvnZgGLfDUtoGgzq6FclJ6a5IUQnpijiHh+9e9bYdjTrqc9MrLplNVS/
PI8W2DDfxGMRlwM1sMdoON/b6HfxOfcej+2uUAsCgYEAsGexvi6gI9D9Yli9Sti+
FH2PV2YYfxfFZwVQPwY33xRivE6loKXA7FPMoWLySqy8+bQOvi98C90iZSRoxjxE
xhATfqO0mmIojZsFnModf1saMyZgleUGSI0qBUnHaeIyELdsKQuVHV8/BqIIL9fs
QX4iECGf4Cffujkuaq76GHcCgYEA0SSGtSsh93Leolp8FRKcn4YjQPcErln6i1C5
A73adup44VUMtG1PEUvt1SS3PUfiPQbMPiHJJtVrdArl4exaJLNVRXPsawKy7Mgb
hDiHoP82GDUCOJ9T+5p5GhhaxvYuGNPrIW2F4hbS7IzA35fY2sPLzKdT1Gm4y/31
ptR4SYsCgYA7aWUKa+SLyDWxGjv5aKWuMnTgV7Wjjbt1D7pjKeOMJrcYIiHmAKqG
ji3fQNQLlBAWcWejUxUBmRUivjm0zvcozvGEv/CUCqBndzZacdjD00QG94KI2xAU
NIhWl6NEtaFHkvfKo489yCmh607EtF/I/xuohH5hHfsMDCVdVbqETw==
-----END RSA PRIVATE KEY-----
EOF

# Nginx runit
mkdir -p /etc/service/nginx/log

cat > /etc/service/nginx/run<<-EOF
#!/bin/sh
exec 2>&1
exec /usr/sbin/nginx -c /etc/nginx/nginx.conf  -g "daemon off;"
EOF

cat > /etc/service/nginx/log/run<<-EOF
#!/bin/sh
set -e
LOG=/var/log/runit/nginx
test -d "\$LOG" || mkdir -p "\$LOG" && exec svlogd -tt "\$LOG"
EOF

chmod +x /etc/service/nginx/run /etc/service/nginx/log/run