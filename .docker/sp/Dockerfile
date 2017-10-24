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
      && a2enmod ssl


RUN cd /etc/shibboleth/ \
    && shib-keygen

RUN mkdir /var/www/html/tul_cob

WORKDIR /var/www/html/tul_cob

ADD Gemfile .

ADD Gemfile.lock .

COPY bin/httpd-foreground /usr/local/bin/
COPY .docker/sp/etc-shibboleth /etc/shibboleth/
COPY .docker/sp/etc-apache-sites-enabled/conf.d/sp.conf /etc/apache2/sites-enabled/000-default.conf

RUN bundle install

EXPOSE 80 443

CMD ["httpd-foreground"]
