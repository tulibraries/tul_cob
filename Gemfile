# frozen_string_literal: true

source "https://rubygems.org"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "6.1.7.3"

gem "alma", git: "https://github.com/tulibraries/alma_rb.git", branch: "main"
gem "autoprefixer-rails"
gem "awesome_print"
gem "bento_search"
gem "blacklight", "~> 7.33.0"
gem "blacklight_advanced_search", git: "https://github.com/projectblacklight/blacklight_advanced_search.git", ref: "v7.0.0"
gem "blacklight-marc"
gem "blacklight_range_limit", git: "https://github.com/tulibraries/blacklight_range_limit.git", branch: "bl-1431-bl-1358"
gem "blacklight-ris", git: "https://github.com/upenn-libraries/blacklight-ris.git"
gem "bootsnap", "1.16.0"
gem "bootstrap", "~> 4.6"
gem "browser"
gem "byebug", platform: :mri
gem "cdm", git: "https://github.com/tulibraries/cdm_rb.git", branch: "master"
gem "cob_az_index", git: "https://github.com/tulibraries/cob_az_index.git",
  branch: "main"
gem "cob_index",
  git: "https://github.com/tulibraries/cob_index.git",
  branch: "main"
gem "cob_web_index", git: "https://github.com/tulibraries/cob_web_index.git",
  branch: "main"
gem "jwt"
gem "coffee-rails", "~> 5.0"
gem "devise", github: "heartcombo/devise"
gem "devise-guests", "~> 0.7"
gem "dotenv-rails"
gem "execjs"
gem "faraday", "2.7.4"
gem "google-analytics-rails", "1.1.1"
gem "hashie", "~>4.1.0"
gem "honeybadger", "5.2.1"
gem "httparty"
gem "jbuilder", "~> 2.11"
gem "jquery-rails"
gem "lc_solr_sortable", git: "https://github.com/tulibraries/lc_solr_sortable", branch: "main"
gem "okcomputer"
gem "omniauth"
gem "omniauth-rails_csrf_protection"
gem "omniauth-shibboleth"
gem "omniauth-saml"
gem "net-smtp"
gem "nokogiri", "1.14.3"
gem "popper_js"
gem "primo", git: "https://github.com/tulibraries/primo", branch: "main"
gem "puma", "6.2.2"
gem "railties"
gem "rsolr", "~> 2.4"
gem "ruby-saml", "1.14.0"
gem "sass-rails", "~> 6.0"
gem "skylight"
gem "turbolinks", "~> 5"
gem "twitter-typeahead-rails", "0.11.1"
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem "uglifier", ">= 1.3.0"
gem "webpacker", "6.0.0.rc.6"

group :development do
  gem "axe-core-rspec"
  gem "flamegraph"
  gem "ruby-prof"
  gem "spring"
  gem "sqlite3"
  gem "stackprof"
  gem "web-console"
end

group :development, :test do
  gem "capybara", "~> 3"
  gem "database_cleaner"
  gem "factory_bot_rails"
  gem "foreman"
  gem "launchy"
  gem "pry-rails"
  gem "rack-mini-profiler", require: false
  gem "rails-controller-testing"
  gem "rspec-rails"
  gem "rubocop"
  gem "rubocop-rails"
  gem "selenium-webdriver"
  gem "simplecov"
  gem "simplecov-lcov"
  gem "vcr"
  gem "webmock"
end

group :production do
  gem "mysql2", "~> 0.5.5"
  # required for using memcached
  gem "dalli"
  gem "connection_pool"
end
