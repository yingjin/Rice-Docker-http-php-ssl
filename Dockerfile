FROM ubuntu:20.04
# Metadata params
ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL
ARG VERSION

LABEL maintainer="Ying Jin <ying.jin@rice.edu>" \
    edu.rice.fondss.name="fon-dss-dspace-test" \
    edu.rice.fondss.description="Digital Scholarship Archive at Rice University" \
    edu.rice.fondss.version=${VERSION} \
    edu.rice.fondss.build-date=${BUILD_DATE} \
    edu.rice.fondss.url="https://localhost" \
    edu.rice.fondss.vcs-url=${VCS_URL} \
    edu.rice.fondss.vcs-ref=${VCS_REF} \
    edu.rice.fondss.schema-version="1.0"

# Env for UTF-8 language encoding
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Env for deb conf
ENV DEBIAN_FRONTEND noninteractive

# General Apache ENVs
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_SERVER_NAME dspace-v2.rice.edu
ENV APACHE_SERVER_URL ${APACHE_SERVER_NAME}
ENV APACHE_SERVER_ADMIN yj4@rice.edu
ENV APACHE_SSL_CERTS ${APACHE_SERVER_URL}.crt
ENV APACHE_SSL_PRIVATE ${APACHE_SERVER_URL}.key
ENV APACHE_SSL_PORT 443
ENV APACHE_LOG_LEVEL info
ENV APACHE_SSL_LOG_LEVEL info
ENV APACHE_SSL_VERIFY_CLIENT optional
ENV APACHE_SSL_SSL_PROXY_ENGINE Off
ENV APACHE_SSL_PROXY_CHECK_PEER_NAME On
ENV APACHE_SERVER_SIGNATURE Off
ENV APACHE_SERVER_TOKENS Prod
ENV APACHE_DOCUMENT_ROOT /var/www/html

# Application specific ENV setup
ENV TOMCAT_INST riceDspace
ENV APP_BASE_PATH /dspace

# For more info See https://httpd.apache.org/docs/2.4/mod/mod_http2.html
ENV APACHE_HTTP_PROTOCOLS http/1.1

# Specifics env Apache for application
ENV APPLICATION_URL https://${APACHE_SERVER_URL}:${APACHE_SSL_PORT}
ENV CLIENT_VERIFY_LANDING_PAGE /error.php

# Reverse Proxy Application
ENV APACHE_PROXY_PRESERVE_HOST On
ENV API_BASE_PATH /secure/api
ENV API_BACKEND_BASE_URL http://127.0.0.1:8000${API_BASE_PATH}

# Install services, packages and do cleanup
RUN apt-get update \
    && apt-get install -y apache2 \
    && apt-get install -y php7.4 libapache2-mod-php7.4 php7.4-xml  \
    && apt-get install -y curl \
    && apt-get install -y git \
    && apt-get install -y wget \
    && apt-get install -y jq \
    && rm -rf /var/lib/apt/lists/*


# Copy Apache configuration file
COPY configs/httpd/000-default.conf /etc/apache2/sites-available/
COPY configs/httpd/default-ssl.conf /etc/apache2/sites-available/
COPY configs/httpd/ssl-params.conf /etc/apache2/conf-available/
COPY configs/httpd/dir.conf /etc/apache2/mods-enabled/
COPY configs/httpd/ports.conf /etc/apache2/

# Copy Server (pub and key)
COPY configs/certs/${APACHE_SSL_CERTS} /etc/ssl/certs/
COPY configs/certs/${APACHE_SSL_PRIVATE} /etc/ssl/private/

# for uv
RUN wget $(curl -s https://api.github.com/repos/UniversalViewer/universalviewer/releases/latest | jq '.tarball_url' | sed 's/"//g') -O uv.tar.gz
RUN tar -xvf uv.tar.gz

#RUN mv $(tar -tf uv.tar.gz | grep dist | head -2 | tail -1) /universalViewer
RUN mkdir -p /var/www/html/uv/; mv $(tar -tf uv.tar.gz | grep dist | head -2 | tail -1) /var/www/html/uv/universalViewer
#/var/www/html/uv/universalViewer

#COPY configs/uv/index.html /var/www/html/uv/index.html

# Copy ohms, help and thumbnails
ADD configs/uv/examples /var/www/html/uv
ADD configs/ohms/html /var/www/html/ohms
ADD configs/help /var/www/html/help
ADD configs/thumbnail /var/www/html/thumbnail

COPY images/favicon.ico /var/www/html/favicon.ico

# Copy scripts and entrypoint
COPY scripts/entrypoint /entrypoint

# Set execute flag for entrypoint
RUN chmod +x /entrypoint \
    && mkdir /run/php \
    && cd /var/www \
    && chown -R www-data:www-data /var/www/html

# Configure and enabled Apache features
RUN a2enmod ssl \
    && a2enmod headers \
    && a2enmod rewrite \
    && a2enmod proxy_fcgi \
    && a2enmod http2 \
    && a2enmod proxy \
    && a2enmod proxy_ajp \
    && a2enmod remoteip \
    && a2enmod php7.4 \
    && a2ensite default-ssl \
    && a2enconf ssl-params \
    && c_rehash /etc/ssl/certs/

# Expose Apache
EXPOSE ${APACHE_SSL_PORT}

# Define entry for setup contrab
ENTRYPOINT ["/entrypoint"]

# Launch Apache
CMD ["/usr/sbin/apache2ctl", "-DFOREGROUND"]
