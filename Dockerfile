FROM ubuntu:18.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends apt-utils && \
    rm -rf /var/lib/apt/lists/* 

RUN apt-get update; \
    apt-get install -y gnupg2; \
	  apt-get install -y wget; \
	  apt-get install -y curl; \
    apt-get install -y git; \
    apt-get install -y libfontconfig1; \
    apt-get install -y libpcre3; \ 
    apt-get install -y libpcre3-dev; \
    apt-get install -y dpkg-dev; \
    apt-get install -y libpng-dev; \
	  apt-get install -y libxslt-dev; \
  	apt-get install -y perl; \
  	apt-get install -y libperl-dev; \
    apt-get install -y libgd3; \
	  apt-get install -y libgd-tools; \
  	apt-get install -y libgd3-dbgsym; \
  	apt-get install -y libgd-dev; \
  	apt-get install -y libgeoip1; \
  	apt-get install -y libgeoip-dev; \
    apt-get install -y geoip-bin; \
	  apt-get install -y libxml2; \
  	apt-get install -y libxml2-dev; \
  	apt-get install -y libxslt1.1; \
    apt-get install -y libxslt1-dev; \
	  apt-get install -y build-essential; \
    apt-get autoclean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* ;
   
	
RUN mkdir -p /tmp/nginx	

WORKDIR /tmp/nginx

ENV NGINX_VERSION 1.18.0

RUN  wget https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz && tar xzvf pcre-8.44.tar.gz && \
     wget https://www.zlib.net/zlib-1.2.11.tar.gz && tar xzvf zlib-1.2.11.tar.gz && \
     wget https://www.openssl.org/source/openssl-1.1.1g.tar.gz && tar xzvf openssl-1.1.1g.tar.gz; \
	 rm -rf *.tar.gz

RUN wget "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -O nginx.tar.gz && \
    tar -xzvf nginx.tar.gz -C /tmp/nginx --strip-components=1 && \
    git clone https://github.com/chobits/ngx_http_proxy_connect_module  /tmp/nginx-modules/ngx_http_proxy_connect_module && \
	patch -p1 < /tmp/nginx-modules/ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_1018.patch;
	
	
RUN  cd /tmp/nginx && ./configure --prefix=/etc/nginx \ 
            --sbin-path=/usr/sbin/nginx \ 
            --modules-path=/usr/lib/nginx/modules \ 
            --conf-path=/etc/nginx/nginx.conf \
            --error-log-path=/var/log/nginx/error.log \
            --pid-path=/var/run/nginx.pid \
            --lock-path=/var/run/nginx.lock \
            --user=nginx \
            --group=nginx \
            --build=Ubuntu \
            --builddir=/tmp/nginx/nginx-${NGINX_VERSION} \
            --with-select_module \
            --with-poll_module \
            --with-threads \
            --with-file-aio \
            --with-http_ssl_module \
            --with-http_v2_module \
            --with-http_realip_module \
            --with-http_addition_module \
            --with-http_xslt_module=dynamic \
            --with-http_image_filter_module=dynamic \
            --with-http_geoip_module=dynamic \
            --with-http_sub_module \
            --with-http_dav_module \
            --with-http_flv_module \
            --with-http_mp4_module \
            --with-http_gunzip_module \
            --with-http_gzip_static_module \
            --with-http_auth_request_module \
            --with-http_random_index_module \
            --with-http_secure_link_module \
            --with-http_degradation_module \
            --with-http_slice_module \
            --with-http_stub_status_module \
            --with-http_perl_module=dynamic \
            --with-perl_modules_path=/usr/share/perl/5.26.1 \
            --with-perl=/usr/bin/perl \
            --http-log-path=/var/log/nginx/access.log \
            --http-client-body-temp-path=/var/cache/nginx/client_temp \
            --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
            --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
            --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
            --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
            --with-mail=dynamic \
            --with-mail_ssl_module \
            --with-stream=dynamic \
            --with-stream_ssl_module \
            --with-stream_realip_module \
            --with-stream_geoip_module=dynamic \
            --with-stream_ssl_preread_module \
            --with-compat \
            --with-pcre=/tmp/nginx/pcre-8.44 \
            --with-pcre-jit \
            --with-zlib=/tmp/nginx/zlib-1.2.11 \
            --with-openssl=/tmp/nginx/openssl-1.1.1g \
            --with-openssl-opt=no-nextprotoneg \
            --with-debug \
	    --add-dynamic-module=/tmp/nginx-modules/ngx_http_proxy_connect_module && \
			  make && \
			  make install;
	
RUN  ln -s /usr/lib/nginx/modules /etc/nginx/modules &&  \
	   mkdir -p /etc/nginx/conf.d /etc/nginx/snippets /etc/nginx/sites-available /etc/nginx/sites-enabled && \
	   adduser --system --home /nonexistent --shell /bin/false --no-create-home --disabled-login --disabled-password --gecos "nginx user" --group nginx && \
     mkdir -p /var/cache/nginx/client_temp /var/cache/nginx/fastcgi_temp /var/cache/nginx/proxy_temp /var/cache/nginx/scgi_temp /var/cache/nginx/uwsgi_temp && \
     chmod 700 /var/cache/nginx/* && \
     chown -R nginx:nginx /var/cache/nginx/* && \
     mkdir -p /var/log/nginx/ && \
     chmod 640 /var/log/nginx/ && \
     hown -R nginx:nginx /var/log/nginx/

RUN cd /tmp/ && rm -ri *
  
  
COPY nginx.conf /etc/nginx/nginx.conf	

COPY mime.types /etc/nginx/mime.types

WORKDIR /etc/nginx

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]