#!/bin/bash
set -e

cp config/secrets.yml.example config/secrets.yml
cp config/alma.yml.example config/alma.yml
cp config/bento.yml.example config/bento.yml
RAILS_ENV=test bundle install --without production
RAILS_ENV=test bundle exec rake db:migrate
RAILS_ENV=test bundle exec rake db:seed
EDITOR='vim -c wqa' bundle exec rails credentials:edit 2> /dev/null
RAILS_ENV=production bundle exec rake assets:precompile
RAILS_ENV=test bundle exec yarn
RAILS_ENV=test bundle exec rails webpacker:compile
