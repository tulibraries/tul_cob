# frozen_string_literal: true

class DatabasesAdvancedController < AdvancedController
  copy_blacklight_config_from(DatabasesController)

  configure_blacklight do |config|
    config.facet_fields = ActiveSupport::OrderedHash.new
    config.add_facet_field "az_format", field: "format", label: "Database Type"
  end

  add_breadcrumb "Databases", :back_to_databases_path, options: { id: "breadcrumbs_databases" }
  add_breadcrumb I18n.t(:databases_advanced_search), :databases_advanced_search_path,
    only: [ :index ]

  protected
    def search_action_url(options = {})
      databases_advanced_search_path(options.merge(action: "index"))
    end
end
