# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap"

Bootsnap.setup(
  cache_dir: ENV.fetch("BOOTSNAP_CACHE_DIR", File.expand_path("../tmp/cache", __dir__)),
  development_mode: ENV["RAILS_ENV"] == "development",
  load_path_cache: true,
  compile_cache_iseq: true,
  compile_cache_yaml: true
)
