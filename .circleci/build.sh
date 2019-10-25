#!/bin/bash
set -e

# Add mysql deps so bundle install doesn't fail.
sudo apt-get install -y libmysqlclient-dev

# Update node version so yarn build doesn't fail.
export NVM_DIR="/opt/circleci/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install v12.13.0 && nvm use v12.13.0 && nvm alias default v12.13.0
node -v

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
