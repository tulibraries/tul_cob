# frozen_string_literal: true

require_relative "boot"

require "rails/all"
require "awesome_print"
require "dot_properties"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Tulcob
  # Rails Application
  class Application < Rails::Application
    config.library_link = "https://library.temple.edu/"
    config.help_link = "https://library.temple.edu/asktulibraries"
    config.load_defaults 5.2
    # Settings in config/environments/* take precedence over those specified
    # here. Application configuration should go into files in
    # config/initializers: All .rb files in that directory are automatically
    # loaded.
    config.process_types = config_for(:process_types).with_indifferent_access
    config.libraries = DotProperties.load(Rails.root + "config/translation_maps/libraries_map.properties")
    config.locations = config_for(:locations).with_indifferent_access
    config.alma = config_for(:alma).with_indifferent_access
    config.bento = config_for(:bento).with_indifferent_access
    config.twilio = config_for(:twilio).with_indifferent_access
    config.devise = config_for(:devise).with_indifferent_access
    config.caches = config_for(:caches).with_indifferent_access
    config.features = Hash.new.with_indifferent_access
    config.exceptions_app = routes
    config.traject_indexer = File.join(Rails.root, "lib/traject/indexer_config.rb")
    ENV["ALLOW_IMPERSONATOR"] ||= "no"

    begin
      config.relative_url_root = config_for(:deploy_to)["path"]
    rescue StandardError => error
      error
    end

    config.generators do |g|
      g.test_framework :rspec, spec: true
      g.fixture_replacement :factory_bot
    end
    #config.log_level = :debug
  end
end
