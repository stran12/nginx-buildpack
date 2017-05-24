#!/bin/bash
# Build NGINX and modules on Heroku.
# This program is designed to run in a web dyno provided by Heroku.
# We would like to build an NGINX binary for the builpack on the
# exact machine in which the binary will run.
# Our motivation for running in a web dyno is that we need a way to
# download the binary once it is built so we can vendor it in the buildpack.
#
# Once the dyno has is 'up' you can open your browser and navigate
# this dyno's directory structure to download the nginx binary.

NGINX_VERSION=${NGINX_VERSION-1.12.0}
PCRE_VERSION=${PCRE_VERSION-8.21}
HEADERS_MORE_VERSION=${HEADERS_MORE_VERSION-0.23}
RESTY_GEOIP2_VERSION=2.0
geoip_db=http://s3.amazonaws.com/rbtv-v3/geoip_db-latest.tgz

nginx_tarball_url=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
pcre_tarball_url=http://garr.dl.sourceforge.net/project/pcre/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.bz2
headers_more_nginx_module_url=https://github.com/agentzh/headers-more-nginx-module/archive/v${HEADERS_MORE_VERSION}.tar.gz

temp_dir=$(mktemp -d /tmp/nginx.XXXXXXXXXX)

echo "Serving files from /tmp on $PORT"
cd /tmp
python -m SimpleHTTPServer $PORT &

cd $temp_dir
echo "Temp dir: $temp_dir"

# echo "Downloading $nginx_tarball_url"
# curl -L $nginx_tarball_url | tar xzv

# echo "Downloading $pcre_tarball_url"
# (cd nginx-${NGINX_VERSION} && curl -L $pcre_tarball_url | tar xvj )

# echo "Downloading $headers_more_nginx_module_url"
# (cd nginx-${NGINX_VERSION} && curl -L $headers_more_nginx_module_url | tar xvz )

# Start of the extra stuff
echo "==============================================="
apt-get -y update && apt-get -y install wget software-properties-common python-software-properties

sudo apt-get clean 
cd /var/lib/apt 
sudo mv lists lists.old 
sudo mkdir -p lists/partial 
sudo apt-get clean 
sudo apt-get update

add-apt-repository ppa:maxmind/ppa

apt-get -y install zip geoip-database libgeoip1 libgeoip-dev libmaxminddb0 libmaxminddb-dev mmdb-bin nginx build-essential libpcre3-dev libssl-dev luarocks

# cd /tmp && wget -c $geoip_db && tar zxvf $geoip_db
cd /tmp && wget -c http://codeload.github.com/leev/ngx_http_geoip2_module/tar.gz/${RESTY_GEOIP2_VERSION} && \
    tar zxvf ${RESTY_GEOIP2_VERSION}

wget -c http://openresty.org/download/openresty-1.11.2.1.tar.gz
tar zxvf openresty-1.11.2.1.tar.gz
(
	cd openresty-1.11.2.1
	./configure \
		--add-module=/tmp/ngx_http_geoip2_module-${RESTY_GEOIP2_VERSION} \
		--sbin-path=/usr/sbin/nginx \
		--conf-path=/etc/nginx/nginx.conf \
		--error-log-path=/var/log/nginx/error.log \
		--http-client-body-temp-path=/var/lib/nginx/body \
		--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
		--http-log-path=/var/log/nginx/access.log \
		--http-proxy-temp-path=/var/lib/nginx/proxy \ 
		# --http-scgi-temp-path=/var/lib/nginx/scgi \ 
		# --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
		# --lock-path=/var/lock/nginx.lock \
		# --pid-path=/var/run/nginx.pid \
		--with-http_geoip_module \
		--with-http_realip_module \
		--with-luajit && \
	luarocks install lua-resty-http && \
	luarocks install lua-cjson && \
	luarocks install lua-resty-jwt && \
	luarocks install uuid && \
	make && \
	make install && \
	apt-get -y autoclean && \
	apt-get -y autoremove
)
echo "==============================================="

# (
# 	cd nginx-${NGINX_VERSION}
# 	./configure \
# 		--with-pcre=pcre-${PCRE_VERSION} \
# 		--prefix=/tmp/nginx \
# 		--add-module=/${temp_dir}/nginx-${NGINX_VERSION}/headers-more-nginx-module-${HEADERS_MORE_VERSION}
# 	make install
# )

while true
do
	sleep 1
	echo "."
done
