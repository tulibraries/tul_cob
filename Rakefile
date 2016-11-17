# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

require 'solr_wrapper/rake_task' unless Rails.env.production?

ZIP_URL = "https://github.com/projectblacklight/blacklight-jetty/archive/v4.10.4.zip"
require 'solr_wrapper'
