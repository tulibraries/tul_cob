FROM ruby:2.4.1
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /tul_cob
WORKDIR /tul_cob
ADD Gemfile .
ADD Gemfile.lock .
ADD sample_data/sample_alma_marcxml.tgz /tmp/
RUN bundle install
