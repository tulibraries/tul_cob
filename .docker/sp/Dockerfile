FROM ruby:2.4.1

RUN apt-get update -qq \
      && apt-get install -y \
      build-essential \
      libpq-dev \
      nodejs \
      apache2 \
      libapache2-mod-shib2 \
      libapache2-mod-passenger \
      && apt-get clean \
      && a2enmod ssl \
      && a2enmod proxy_http

ADD Gemfile .

ADD Gemfile.lock .

RUN bundle install

WORKDIR /var/www/html/tul_cob

COPY bin/httpd-foreground /usr/local/bin/

CMD ["httpd-foreground"]
