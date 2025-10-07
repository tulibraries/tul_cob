# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "7.1.5.2"

gem "actionpack-action_caching", "~> 1.2"
gem "actionpack-page_caching", "~> 1.2"
gem "alma", git: "https://github.com/tulibraries/alma_rb.git", branch: "main"
gem "autoprefixer-rails"
gem "awesome_print"
gem "bento_search", git: "https://github.com/tulibraries/bento_search.git", branch: "temple-libraries-rails7-upgrade"
gem "blacklight", "~> 7.41"
gem "blacklight-marc"
gem "blacklight-ris", git: "https://github.com/tulibraries/blacklight-ris.git", branch: "update-for-rails-7-blacklight-7"
gem "blacklight_advanced_search", git: "https://github.com/projectblacklight/blacklight_advanced_search.git", ref: "v7.0.0"
gem "blacklight_range_limit", git: "https://github.com/tulibraries/blacklight_range_limit.git", branch: "bl-1431-bl-1358"
gem "bootstrap", ">= 5.3.3"
gem "bootsnap", "1.18.6"
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
gem "coffee-rails"
gem "concurrent-ruby"
gem "devise"
gem "devise-guests", "~> 0.8"
gem "dotenv-rails"
gem "execjs"
gem "faraday", "2.14.0"
gem "ffi", "1.16.3"
gem "hashie", "~>4.1.0"
gem "honeybadger", "6.1.0"
gem "httparty"
gem "jbuilder", "~> 2.14"
gem "jquery-rails"
gem "jwt"
gem "lc_solr_sortable", git: "https://github.com/tulibraries/lc_solr_sortable", branch: "main"
gem "net-smtp"
gem "nokogiri", "1.18.10"
gem "okcomputer"
gem "omniauth"
gem "omniauth-rails_csrf_protection"
gem "omniauth-saml"
gem "omniauth-shibboleth"
gem "popper_js", ">= 2.11.8"
gem "primo", git: "https://github.com/tulibraries/primo", branch: "main"
gem "puma", "7.0.4"
gem "psych"
gem "rsolr", "~> 2.6"
gem "ruby-saml", "1.18.1"
gem "sass-rails"
gem "skylight"
gem "sprockets-rails"
gem "turbolinks", "~> 5"
gem "turbo-rails"
gem "twitter-typeahead-rails", "0.11.1"
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem "uglifier", ">= 1.3.0"
gem "webpacker", "6.0.0.rc.6"

group :development do
  gem "axe-core-rspec"
  gem "flamegraph"
  gem "foreman"
  gem "launchy"
  gem "rack-mini-profiler", require: false
  gem "ruby-prof"
  gem "stackprof"
  gem "web-console"
end

group :development, :test do
  gem "pry-rails"
  gem "rubocop"
  gem "rubocop-rails"
end

group :test do
  gem "capybara", "~> 3"
  gem "database_cleaner"
  gem "factory_bot_rails"
  gem "rails-controller-testing"
  gem "rspec-rails"
  gem "selenium-webdriver"
  gem "simplecov"
  gem "simplecov-lcov"
  gem "spring"
  gem "sqlite3", "~> 1.7.3"
  gem "vcr"
  gem "webmock"
end

group :production do
  gem "pg"
  # required for using memcached
  gem "dalli"
  gem "connection_pool"
end

gem "recaptcha", "~> 5.21"
