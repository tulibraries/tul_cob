# frozen_string_literal: true

require_relative "boot"

require "rails/all"
require "awesome_print"
require "dot_properties"
require "./lib/alma/config_utils"

Bundler.require(*Rails.groups)

module Tulcob
  class Application < Rails::Application
    # Before filter for Flipflop dashboard. Replace with a lambda or method name
    # defined in ApplicationController to implement access control.
    config.flipflop.dashboard_access_filter = -> {
      head :forbidden unless User.logged_in?
    }
    # By default, when set to `nil`, strategy loading errors are suppressed in test
    # mode. Set to `true` to always raise errors, or `false` to always warn.
    config.flipflop.raise_strategy_errors = nil

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    require "lc_classifications"
    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))
    config.add_autoload_paths_to_load_path = true
    config.autoload_paths << Rails.root.join("lib")

    config.library_link = "https://library.temple.edu/"
    config.ask_link = "https://library.temple.edu/contact-us"
    config.process_types = config_for(:process_types).with_indifferent_access
    config.libraries = CobIndex::DotProperties.load("libraries_map")
    cob_index_path = Gem::Specification.find_by_name("cob_index").gem_dir
    config.locations = YAML.load_file(cob_index_path + "/lib/translation_maps/locations.yaml").with_indifferent_access
    config.material_types = config_for(:material_types).with_indifferent_access
    config.alma = config_for(:alma).with_indifferent_access
    config.bento = config_for(:bento).with_indifferent_access
    config.cdm = config_for(:cdm_collection).with_indifferent_access
    config.email_groups = config_for(:email_groups).with_indifferent_access
    config.oclc = config_for(:oclc).with_indifferent_access
    config.lib_guides = config_for(:lib_guides).with_indifferent_access
    config.devise = config_for(:devise).with_indifferent_access
    config.caches = config_for(:caches).with_indifferent_access
    config.features = Hash.new.with_indifferent_access
    config.quik_pay = config_for(:quik_pay).with_indifferent_access
    config.exceptions_app = routes
    config.time_zone = "Eastern Time (US & Canada)"
    config.active_record.default_timezone = :local
    config.microsoft_graph_mailer = config_for(:microsoft_graph_mailer).with_indifferent_access

    config.generators do |g|
      g.test_framework :rspec, spec: true
      g.fixture_replacement :factory_bot
    end
    #config.log_level = :debug

    # Could be removed once this issue is fixed:
    # https://github.com/heartcombo/devise/pull/5462
    config.action_controller.raise_on_open_redirects = false
  end
end
