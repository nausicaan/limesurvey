FROM nginx:1.27.0

ARG USER="1014150000"
ARG CONFIG="limesurvey.conf"

# Install the GNU Compiler Collection
RUN apt-get update && apt-get install -y \
        gcc mono-mcs \
    && rm -rf /var/lib/apt/lists/* \
    && rm /etc/nginx/conf.d/default.conf \
    # Create the necessary directories
    && mkdir -p /var/cache/nginx/client_temp \
        /var/cache/nginx/proxy_temp \
        /var/cache/nginx/fastcgi_temp \
        /var/cache/nginx/scgi_temp \
        /var/cache/nginx/uwsgi_temp \
        /etc/nginx/sites-available \
        /etc/nginx/sites-enabled \
        /etc/nginx/blocklists \
    # Claim ownership for the OpenShift default user (unique per namespace)
    && chown -R ${USER}:root /etc/nginx

# Copy the NGINX configuration files
ADD ${CONFIG} /etc/nginx/sites-available
ADD nginx.pid /var/log/nginx
ADD nginx.conf /etc/nginx

RUN ln -s /etc/nginx/sites-available/${CONFIG} /etc/nginx/sites-enabled/${CONFIG}