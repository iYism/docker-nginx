# Dockerfile - Nginx

ARG USER=nginx
ARG CONF_DIR=/etc/nginx
ARG HOME_DIR=/opt/nginx
ARG DATA_DIR=/var/lib/nginx
ARG LOGS_DIR=/var/log/nginx
ARG LUA_LIB=${HOME_DIR}/lualib
ARG LUA_MOD=${HOME_DIR}/luamod
ARG BUILD_DIR=/tmp/.build.nginx


# Build Stage
FROM rockylinux:9 AS builder
LABEL maintainer="iYism <admin@iyism.com>"

# Component versions
ENV NGINX_VERSION=1.29.1 \
    ZLIB_VERSION=1.3.1 \
    PCRE2_VERSION=10.46 \
    OPENSSL_VERSION=3.5.2 \
    GEOIP_VERSION=1.6.12 \
    BROTLI_VERSION=1.0.9 \
    NGX_BROTLI_VERSION=master \
    NGX_GEOIP2_VERSION=3.4 \
    NGX_DEVEL_KIT_VERSION=0.3.3 \
    LUAJIT_VERSION=2.1-20250529 \
    ECHO_NGINX_VERSION=0.63 \
    LUA_NGINX_VERSION=0.10.28 \
    LUA_CJSON_VERSION=2.1.0.14 \
    RESTY_CORE_VERSION=0.1.31 \
    RESTY_LOCK_VERSION=0.09 \
    RESTY_LRUCACHE_VERSION=0.15

# Set environment variables for the build stage
ARG USER \
    CONF_DIR \
    HOME_DIR \
    DATA_DIR \
    LOGS_DIR \
    LUA_LIB \
    LUA_MOD \
    BUILD_DIR

# Switching to root to install the required packages
USER root

WORKDIR ${BUILD_DIR}

RUN set -x \
# Mkdir basedir
    && mkdir -p ${LUA_LIB} ${LUA_MOD} \
# Install development packages
    && dnf install -y dnf-plugins-core \
    && dnf config-manager --enable devel \
    && dnf install -y make gcc gcc-c++ perl diffutils autoconf automake libtool procps-ng \
        gd-devel brotli-devel libxslt-devel libxml2-devel libmaxminddb-devel \
# Install zlib
    && curl -LO --output-dir ${BUILD_DIR} https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz \
    && tar zxf zlib-${ZLIB_VERSION}.tar.gz \
    && cd zlib-${ZLIB_VERSION} \
    && ./configure --prefix=${HOME_DIR}/zlib \
    && make -j`nproc` \
    && make install \
    && cd ${BUILD_DIR} \
# Install pcre2
    && curl -LO --output-dir ${BUILD_DIR} https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VERSION}/pcre2-${PCRE2_VERSION}.tar.gz \
    && tar zxf pcre2-${PCRE2_VERSION}.tar.gz \
    && cd pcre2-${PCRE2_VERSION} \
    && ./configure --prefix=${HOME_DIR}/pcre2 \
        --enable-jit \
        --enable-pcre2-16 \
        --enable-pcre2-32 \
    && make -j`nproc` \
    && make install \
    && cd ${BUILD_DIR} \
# Install openssl
    && curl -LO --output-dir ${BUILD_DIR} https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz \
    && tar zxf openssl-${OPENSSL_VERSION}.tar.gz \
    && cd openssl-${OPENSSL_VERSION} \
    && ./Configure --prefix=${HOME_DIR}/openssl34 \
        shared zlib \
        --libdir=lib64 \
        -I${HOME_DIR}/zlib/include \
        -L${HOME_DIR}/zlib/lib \
        -Wl,-rpath,${HOME_DIR}/zlib/lib:${HOME_DIR}/openssl34/lib64 \
    && make -j`nproc` \
    && make install_sw \
    && cd ${BUILD_DIR} \
# Install geoip-api-c
    && curl -LJO --output-dir ${BUILD_DIR} https://github.com/maxmind/geoip-api-c/archive/refs/tags/v${GEOIP_VERSION}.tar.gz \
    && tar zxf geoip-api-c-${GEOIP_VERSION}.tar.gz \
    && cd geoip-api-c-${GEOIP_VERSION} \
    && ./bootstrap \
    && ./configure --prefix=${HOME_DIR}/geoip \
    && make \
    && make install \
    && cd ${BUILD_DIR} \
# Download ngx_http_geoip2_module
    && curl -LJO --output-dir ${BUILD_DIR} https://github.com/leev/ngx_http_geoip2_module/archive/refs/tags/${NGX_GEOIP2_VERSION}.tar.gz \
    && tar zxf ngx_http_geoip2_module-${NGX_GEOIP2_VERSION}.tar.gz \
    && cd ${BUILD_DIR} \
# Download ngx_devel_kit
    && curl -LJO --output-dir ${BUILD_DIR} https://github.com/vision5/ngx_devel_kit/archive/refs/tags/v${NGX_DEVEL_KIT_VERSION}.tar.gz \
    && tar zxf ngx_devel_kit-${NGX_DEVEL_KIT_VERSION}.tar.gz \
    && cd ${BUILD_DIR} \
# Download echo-nginx-module
    && curl -LJO --output-dir ${BUILD_DIR} https://github.com/openresty/echo-nginx-module/archive/refs/tags/v${ECHO_NGINX_VERSION}.tar.gz \
    && tar zxf echo-nginx-module-${ECHO_NGINX_VERSION}.tar.gz \
    && cd ${BUILD_DIR} \
# Install luajit
    && curl -LJO --output-dir ${BUILD_DIR} https://github.com/openresty/luajit2/archive/refs/tags/v${LUAJIT_VERSION}.tar.gz \
    && tar zxf luajit2-${LUAJIT_VERSION}.tar.gz \
    && cd luajit2-${LUAJIT_VERSION} \
    && make -j`nproc` XCFLAGS='-DLUAJIT_ENABLE_GC64' \
    && make install PREFIX=${HOME_DIR}/luajit \
    && cd ${BUILD_DIR} \
# Download lua-nginx-module
    && curl -LJO --output-dir ${BUILD_DIR} https://github.com/openresty/lua-nginx-module/archive/refs/tags/v${LUA_NGINX_VERSION}.tar.gz \
    && tar zxf lua-nginx-module-${LUA_NGINX_VERSION}.tar.gz \
    && cd ${BUILD_DIR} \
# Download ngx_brotli
    && curl -LJO --output-dir ${BUILD_DIR} https://github.com/google/ngx_brotli/archive/refs/heads/${NGX_BROTLI_VERSION}.tar.gz \
    && tar zxf ngx_brotli-${NGX_BROTLI_VERSION}.tar.gz \
    && curl -LJO --output-dir ${BUILD_DIR} https://github.com/google/brotli/archive/refs/tags/v${BROTLI_VERSION}.tar.gz \
    && rm -fr ngx_brotli-${NGX_BROTLI_VERSION}/deps/brotli \
    && tar zxf brotli-${BROTLI_VERSION}.tar.gz -C ngx_brotli-${NGX_BROTLI_VERSION}/deps \
    && mv ngx_brotli-${NGX_BROTLI_VERSION}/deps/brotli-${BROTLI_VERSION} ngx_brotli-${NGX_BROTLI_VERSION}/deps/brotli \
# Install nginx
    && curl -LO --output-dir ${BUILD_DIR} https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar zxf nginx-${NGINX_VERSION}.tar.gz \
    && cd nginx-${NGINX_VERSION} \
    && export LUAJIT_LIB=${HOME_DIR}/luajit/lib \
    && export LUAJIT_INC=${HOME_DIR}/luajit/include/luajit-2.1 \
    && ./configure \
       --prefix=${HOME_DIR}/nginx \
       --sbin-path=/usr/sbin/nginx \
       --conf-path=${CONF_DIR}/nginx.conf \
       --modules-path=${HOME_DIR}/nginx/modules \
       --error-log-path=${LOGS_DIR}/error.log \
       --http-log-path=${LOGS_DIR}/access.log \
       --pid-path=/run/nginx.pid \
       --lock-path=/run/nginx.lock \
       --http-client-body-temp-path=${DATA_DIR}/client_temp \
       --http-proxy-temp-path=${DATA_DIR}/proxy_temp \
       --http-fastcgi-temp-path=${DATA_DIR}/fastcgi_temp \
       --http-uwsgi-temp-path=${DATA_DIR}/uwsgi_temp \
       --http-scgi-temp-path=${DATA_DIR}/scgi_temp \
       --user=$USER \
       --group=$USER \
       --with-threads \
       --with-file-aio \
       --with-http_ssl_module \
       --with-http_v2_module \
       --with-http_v3_module \
       --with-http_realip_module \
       --with-http_addition_module \
       --with-http_xslt_module \
       --with-http_image_filter_module \
       --with-http_geoip_module \
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
       --with-mail \
       --with-mail_ssl_module \
       --with-stream \
       --with-stream_ssl_module \
       --with-stream_realip_module \
       --with-stream_geoip_module \
       --with-stream_ssl_preread_module \
       --with-compat \
       --with-pcre \
       --with-pcre-jit \
       --add-module=${BUILD_DIR}/ngx_devel_kit-${NGX_DEVEL_KIT_VERSION} \
       --add-module=${BUILD_DIR}/echo-nginx-module-${ECHO_NGINX_VERSION} \
       --add-module=${BUILD_DIR}/ngx_http_geoip2_module-${NGX_GEOIP2_VERSION} \
       --add-module=${BUILD_DIR}/ngx_brotli-${NGX_BROTLI_VERSION} \
       --add-module=${BUILD_DIR}/lua-nginx-module-${LUA_NGINX_VERSION} \
       --with-cc-opt="-fPIE -O2 -DNGX_LUA_ABORT_AT_PANIC -I${HOME_DIR}/zlib/include -I${HOME_DIR}/geoip/include -I${HOME_DIR}/pcre2/include -I${HOME_DIR}/openssl34/include" \
       --with-ld-opt="-pie -Wl,-rpath,${HOME_DIR}/luajit/lib -L${HOME_DIR}/zlib/lib -L${HOME_DIR}/geoip/lib -L${HOME_DIR}/pcre2/lib -L${HOME_DIR}/openssl34/lib64 -Wl,-rpath,${HOME_DIR}/zlib/lib:${HOME_DIR}/geoip/lib:${HOME_DIR}/pcre2/lib:${HOME_DIR}/openssl34/lib64" \
    && make -j`nproc` \
    && make install \
    && cd ${BUILD_DIR} \
# Install lua-resty-core
    && curl -LJO --output-dir ${BUILD_DIR} https://github.com/openresty/lua-resty-core/archive/refs/tags/v${RESTY_CORE_VERSION}.tar.gz \
    && tar zxf lua-resty-core-${RESTY_CORE_VERSION}.tar.gz \
    && cp -fr lua-resty-core-${RESTY_CORE_VERSION}/lib/* ${LUA_LIB} \
    && cd ${BUILD_DIR} \
# Install lua-resty-lrucache
    && curl -LJO --output-dir ${BUILD_DIR} https://github.com/openresty/lua-resty-lrucache/archive/refs/tags/v${RESTY_LRUCACHE_VERSION}.tar.gz \
    && tar zxf lua-resty-lrucache-${RESTY_LRUCACHE_VERSION}.tar.gz \
    && cp -fr lua-resty-lrucache-${RESTY_LRUCACHE_VERSION}/lib/* ${LUA_LIB} \
    && cd ${BUILD_DIR} \
# Install lua-resty-lock
    && curl -LJO --output-dir ${BUILD_DIR} https://github.com/openresty/lua-resty-lock/archive/refs/tags/v${RESTY_LOCK_VERSION}.tar.gz \
    && tar zxf lua-resty-lock-${RESTY_LOCK_VERSION}.tar.gz \
    && cp -fr lua-resty-lock-${RESTY_LOCK_VERSION}/lib/* ${LUA_LIB} \
    && cd ${BUILD_DIR} \
# Install lua-cjson
    && curl -LJO --output-dir ${BUILD_DIR} https://github.com/openresty/lua-cjson/archive/refs/tags/${LUA_CJSON_VERSION}.tar.gz \
    && tar zxf lua-cjson-${LUA_CJSON_VERSION}.tar.gz \
    && cd lua-cjson-${LUA_CJSON_VERSION} \
    && make LUA_INCLUDE_DIR=${HOME_DIR}/luajit/include/luajit-2.1 \
    && cp -a cjson.so ${LUA_MOD} \
# Clean tmpdata
    && cd ${HOME_DIR} \
    && rm -fr ${BUILD_DIR} \
    && dnf config-manager --disable devel \
    && dnf remove -y make gcc gcc-c++ perl diffutils autoconf automake libtool dnf-plugins-core \
    && dnf remove -y --noautoremove gd-devel brotli-devel libxslt-devel libxml2-devel libmaxminddb-devel \
    && dnf clean all

COPY nginx.conf /etc/nginx/nginx.conf
COPY vhost.default.conf /etc/nginx/conf.d/default.conf


# Runtime Stage
FROM rockylinux:9-minimal

# Set environment variables for the runtime stage
ARG USER \
    CONF_DIR \
    HOME_DIR \
    DATA_DIR \
    LOGS_DIR \
    LUA_LIB \
    LUA_MOD

COPY --from=builder ${CONF_DIR} ${CONF_DIR}
COPY --from=builder ${HOME_DIR} ${HOME_DIR}
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx

RUN set -x \
# Add nginx user
    && getent group $USER >/dev/null || groupadd -r $USER -g 101 \
    && getent passwd $USER >/dev/null || useradd -r -u 101 -g $USER -s /sbin/nologin \
        -d ${DATA_DIR} -m -c "$USER user" $USER \
# Create the directories required for NGINX dependencies
    && mkdir -p ${DATA_DIR} ${LOGS_DIR} \
# Install required packages
    && microdnf install -y gd brotli libxslt libxml2 libmaxminddb \
    && microdnf clean all

# Add Lua paths
ENV LUA_PATH="${LUA_LIB}/?.lua;${HOME_DIR}/luajit/share/luajit-2.1/?.lua;./?.lua;/usr/local/share/luajit-2.1/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua"
ENV LUA_CPATH="${LUA_MOD}/?.so;./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so"

# Add custom compiled binaries to the PATH
ENV PATH=$HOME_DIR/geoip/bin:$HOME_DIR/luajit/bin:$HOME_DIR/openssl34/bin:$HOME_DIR/pcre2/bin:$PATH

# Set the working directory to the NGINX home directory
WORKDIR ${HOME_DIR}

# Expose Nginx ports
EXPOSE 80 443

# Start the Nginx server
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]

# Set the signal that will be used to stop the container
STOPSIGNAL SIGQUIT
