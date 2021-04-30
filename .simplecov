# frozen_string_literal: true

require "simplecov-lcov"

SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter

SimpleCov.start "rails" do
  # Code from other repositories
  add_filter "/lib/alma_rb/"
  add_filter "/lib/alma-blacklight/"
  add_filter "/app/models/marc_indexer.rb"
  add_filter "/app/views/"
  add_filter "/app/channels/"
  add_filter "/spec/"
end
