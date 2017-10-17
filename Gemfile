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

group :development do
  # Access an IRB console on exception pages or by using <%= console %>
  # anywhere in the code.
  gem "listen", "~> 3.0.5"
  gem "web-console"
  # Spring speeds up development by keeping your application running in the
  # background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[mingw mswin x64_mingw jruby]

gem "blacklight"
gem "blacklight-marc"
gem "blacklight_advanced_search"
gem "blacklight_range_limit"

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger
  # console.
  gem "byebug", platform: :mri
  gem "database_cleaner"
  gem "factory_girl_rails"
  gem "foreman"
  gem "guard-rspec", require: false
  gem "guard-shell"
  gem "launchy"
  gem "pry-rails"
  gem "rspec-rails"
  gem "simplecov", require: false
  gem "solr_wrapper", ">= 0.3"
end

gem "alma", "~> 0.2.4"
gem "awesome_print"
gem "bento_search"
gem "blacklight_alma", git: "https://github.com/tulibraries/blacklight_alma.git"
gem "capybara"
gem "chosen-rails"
gem "devise"
gem "devise-guests", "~> 0.5"
gem "ezwadl"
# 1/31/17 - Hashie 3.5.0 breaks omniauth, so peg to previous
gem "hashie", "~>3.4.6"
gem "omniauth"
gem "omniauth-alma", git: "https://github.com/tulibraries/omniauth-alma.git"
gem "rsolr", "~> 1.0"
gem "webmock"
