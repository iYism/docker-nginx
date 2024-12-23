# FreeNGINX Docker Image

Built on **Rocky Linux 9**, this repository provides a custom Docker image for FreeNGINX, designed for high-performance web applications. It supports Lua scripting, PCRE2, and HTTP/3 with QUIC (via OpenSSL). 

## Features

- **Lua Scripting**: Use LuaJIT with the lua-nginx-module for dynamic request handling and flexible configuration.
- **PCRE2 Support**: Enhanced regular expressions with JIT compilation for improved performance.
- **QUIC and HTTP/3 Support**: Faster, reliable connections with modern protocols.
- **Brotli Compression**: Efficient compression for faster loading of static resources.

## Components

* **FreeNGINX**: Version `1.27.4`
* **zlib**: Version `1.3.1`
* **PCRE2**: Version `10.44`
* **OpenSSL**: Version `3.3.2`
* **geoip-api-c**: Version `1.6.12`
* **brotli**: Version `1.0.9`
* **ngx_brotli**: Version `master`
* **ngx_http_geoip2_module**: Version `3.4`
* **ngx_devel_kit**: Version `0.3.3`
* **LuaJIT**: Version `2.1-20240815`
* **echo-nginx-module**: Version `0.63`
* **lua-nginx-module**: Version `0.10.27`
* **lua-cjson**: Version `2.1.0.14`
* **lua-resty-core**: Version `0.1.29`
* **lua-resty-lock**: Version `0.09`
* **lua-resty-lrucache**: Version `0.14`

## Quick Start

### Build the Docker Image

Build the Docker image locally:
```sh
docker build -t nginx:latest .
```

### Run the Container

You can run the FreeNGINX container using the following command:
```sh
docker run -d -p 80:80 -p 443:443 --name nginx nginx:latest
```

This will start FreeNGINX with the default configuration.

### Custom NGINX Configuration

You can customize the NGINX configuration by mounting your own configuration files into the container:
```sh
docker run -d \
  -v /etc/nginx:/etc/nginx \
  -v /data/public:/data/public \
  -p 80:80/tcp \
  -p 443:443/tcp \
  -p 443:443/udp \
  --name nginx \
  nginx:latest
```

You can also include custom Lua scripts, or other configuration options as needed.

### HTTP/2, QUIC + HTTP/3 Configuration

To enable HTTP/2, QUIC and HTTP/3 in FreeNGINX, you typically configure your server block as follows:
```sh
server {
    listen 443 ssl reuseport;
    listen [::]:443 ssl reuseport;
    listen 443 quic reuseport;
    listen [::]:443 quic reuseport;

    http2 on;
    http3 on;

    server_name localhost;
    index index.html index.htm;

    ssl_certificate /path/to/signed_cert_plus_intermediates;
    ssl_certificate_key /path/to/private_key;

    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:16m;

    # openssl dhparam -out /path/to/dhparam.pem 2048
    ssl_dhparam /path/to/dhparam.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305";

    ssl_conf_command Ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256;
    ssl_prefer_server_ciphers on;

    # enable acceptance of 0-RTT data in TLS 1.3
    #ssl_early_data on;

    # OCSP stapling
    ssl_stapling on;
    ssl_stapling_verify on;

    # replace with the IP address of your resolver
    resolver 1.1.1.1 8.8.8.8 valid=300s;
    resolver_timeout 15s;

    # used to advertise the availability of HTTP/3
    add_header Alt-Svc 'h3=":443"; ma=86400';

    # adds a custom request ID header for request tracing; always adds this header
    add_header X-Request-ID $request_id always;

    # restricts frame embedding to the same origin to prevent clickjacking attacks
    add_header X-Frame-Options "SAMEORIGIN";

    # enables XSS protection to prevent cross-site scripting attacks, using block mode
    add_header X-XSS-Protection "1; mode=block";

    # prevents MIME type sniffing, ensuring the browser handles the response as declared
    add_header X-Content-Type-Options "nosniff";

    # enables HTTP Strict Transport Security (HSTS), instructing browsers to only access the site via HTTPS for 1 year
    add_header Strict-Transport-Security "max-age=31536000" always;

    location / {
        root /your/data;
    }

    access_log /var/log/nginx/access.log main;
}
```

## Contributing

Contributions are welcome! Please feel free to submit issues, pull requests, or suggestions.
