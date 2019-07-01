# frozen_string_literal: true

source "https://rubygems.org"


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 5.2"
# Use sqlite3 as the database for Active Record
gem "sqlite3"
# Use Puma as the app server
gem "puma", "~> 3.12"
gem "bootstrap", "~> 4.3"
gem "popper_js"
gem "twitter-typeahead-rails", "0.11.1"
# Use SCSS for stylesheets
gem "sass-rails", "~> 5.0"
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"
# Use CoffeeScript for .coffee assets and views
gem "coffee-rails", "~> 5.0"
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem "jquery-rails"
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem "turbolinks", "~> 5"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.9"
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
  gem "coveralls"
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem "web-console"
  gem "listen", "~> 3.1.5"
  # spring speeds up development by keeping your application running in the background. read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
end

# windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem "blacklight", "~> 7.0"
gem "blacklight_advanced_search", git: "https://github.com/projectblacklight/blacklight_advanced_search.git"
gem "blacklight-marc", git: "https://github.com/projectblacklight/blacklight-marc.git", ref: "v7.0.0.rc1"
gem "blacklight_range_limit", git: "https://github.com/projectblacklight/blacklight_range_limit.git", ref: "v7.0.0.rc2"

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
  gem "rails-controller-testing"
  gem "rubocop"
end

gem "rsolr", "~> 2.2"
gem "devise"
gem "devise-guests", "~> 0.7"
gem "alma", git: "https://github.com/tulibraries/alma_rb.git", branch: "master"
gem "cdm", git: "https://github.com/tulibraries/cdm_rb.git", branch: "master"
# 1/31/17 - Hashie 3.5.0 breaks omniauth, so peg to previous
gem "hashie", "~>3.6.0"
gem "omniauth"
gem "blacklight_alma", git: "https://github.com/tulibraries/blacklight_alma.git", branch: "update-blacklight"
gem "ezwadl"
gem "awesome_print"
gem "capybara", "3.25.0"
gem "webmock"
gem "bento_search"
gem "omniauth-shibboleth"
gem "skylight"
gem "webpacker"
gem "google-analytics-rails", "1.1.1"
gem "primo", git: "https://github.com/tulibraries/primo"
gem "bootsnap"
gem "honeybadger"
gem "browser"
gem "blacklight-ris", git: "https://github.com/upenn-libraries/blacklight-ris.git"
gem "bootstrap-select-rails"
gem "httparty"
gem "breadcrumbs_on_rails"

gem "traject", "~> 3.1"
gem "traject_plus"

group :production do
  gem "mysql2", "~> 0.5.2"
end

# devops
gem "okcomputer"
