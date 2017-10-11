FROM ruby:2.4.1
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /tul_cob
WORKDIR /tul_cob
ADD Gemfile /tul_cob/Gemfile
ADD Gemfile.lock /tul_cob/Gemfile.lock
ADD config/bento.yml.example /tul_cob/config/bento.yml
ADD config/alma.yml.example /tul_cob/config/alma.yml
RUN bundle install
ADD . /tul_cob
