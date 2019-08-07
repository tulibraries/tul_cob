# frozen_string_literal: true

class DatabasesAdvancedController < AdvancedController
  copy_blacklight_config_from(DatabasesController)

  configure_blacklight do |config|
    config.facet_fields = ActiveSupport::OrderedHash.new
    config.add_facet_field "az_format", field: "format", label: "Database Type"
  end

  protected
    def search_action_url(options = {})
      databases_advanced_search_path(options.merge(action: "index"))
    end
end
