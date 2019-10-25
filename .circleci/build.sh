#!/bin/bash
set -e

curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt-get install -y libmysqlclient-dev nodejs

cp config/secrets.yml.example config/secrets.yml
cp config/alma.yml.example config/alma.yml
cp config/bento.yml.example config/bento.yml

RAILS_ENV=test bundle install
RAILS_ENV=test bundle exec rake db:migrate
RAILS_ENV=test bundle exec rake db:seed
EDITOR='vim -c wqa' bundle exec rails credentials:edit 2> /dev/null
RAILS_ENV=production bundle exec rake assets:precompile
RAILS_ENV=test bundle exec yarn
RAILS_ENV=test bundle exec rails webpacker:compile
