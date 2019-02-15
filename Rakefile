# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be
# available to Rake.

if Rake.application.top_level_tasks.any? { |arg| arg.match(/^docker/) }
  # We connot assume that bundle install has run on the host.
  require_relative "lib/tasks/docker"
else
  require_relative "config/application"

  Rails.application.load_tasks

  Rake::Task[:default].clear
  task default: :ci

  require "solr_wrapper/rake_task" unless Rails.env.production?
end
