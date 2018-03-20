# frozen_string_literal: true

source "https://rubygems.org"


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 5.0.1"
# Use sqlite3 as the database for Active Record
gem "sqlite3"
# Use Puma as the app server
gem "puma", "~> 3.0"
# Use SCSS for stylesheets
gem "sass-rails", "~> 5.0"
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"
# Use CoffeeScript for .coffee assets and views
gem "coffee-rails", "~> 4.2"
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem "jquery-rails"
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem "turbolinks", "~> 5"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.5"
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platform: :mri
  gem "pry-rails"
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem "web-console"
  gem "listen", "~> 3.0.5"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "blacklight"
gem "blacklight_advanced_search"
gem "blacklight-marc"
gem "blacklight_range_limit"

group :development, :test do
  gem "solr_wrapper", ">= 0.3"
  gem "rspec-rails"
  gem "database_cleaner"
  gem "factory_bot_rails"
  gem "simplecov", require: false
  gem "guard-rspec", require: false
  gem "guard-shell"
  gem "launchy"
  gem "foreman"
  gem "vcr"
  gem "pretender"
  gem "rails-controller-testing"
  gem "faker"
  gem "rubocop"
end



gem "rsolr", "~> 1.0"
gem "devise"
gem "devise-guests", "~> 0.5"
gem "alma", git: "https://github.com/tulibraries/alma_rb"
# 1/31/17 - Hashie 3.5.0 breaks omniauth, so peg to previous
gem "hashie", "~>3.4.6"
gem "omniauth"
gem "blacklight_alma", git: "https://github.com/tulibraries/blacklight_alma.git"
gem "ezwadl"
gem "awesome_print"
gem "capybara"
gem "webmock"
gem "chosen-rails"
gem "bento_search"
gem "omniauth-shibboleth"
gem "twilio-ruby"
gem "skylight"
gem "webpacker"



group :production do
  gem "mysql2", "~> 0.4.9"
end
