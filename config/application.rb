# frozen_string_literal: true

require_relative "boot"

require "rails/all"
require "awesome_print"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Tulcob
  # Rails Application
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified
    # here. Application configuration should go into files in
    # config/initializers: All .rb files in that directory are automatically
    # loaded.
    config.locations = config_for(:locations).with_indifferent_access
    config.alma = config_for(:alma).with_indifferent_access
    config.bento = config_for(:bento).with_indifferent_access
    config.twilio = config_for(:twilio).with_indifferent_access
    config.exceptions_app = routes
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
