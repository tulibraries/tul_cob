FROM tulcob_app:latest

RUN apt-get update -qq \
      && apt-get install -y \
      apache2 \
      libapache2-mod-shib2 \
      libapache2-mod-passenger \
      && apt-get clean \
      && a2enmod ssl \
      && a2enmod proxy_http

WORKDIR /var/www/html/tul_cob

COPY bin/httpd-foreground /usr/local/bin/

CMD ["httpd-foreground"]
