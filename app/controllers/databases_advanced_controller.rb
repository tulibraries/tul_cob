# frozen_string_literal: true

class DatabasesAdvancedController < AdvancedController
  copy_blacklight_config_from(DatabasesController)

  add_breadcrumb "Databases", :back_to_databases_path, options: { id: "breadcrumbs_databases" }
  add_breadcrumb I18n.t(:databases_advanced_search), :databases_advanced_search_path,
    only: [ :index ]

  protected
    def search_action_url(options = {})
      databases_advanced_search_path(options.merge(action: "index"))
    end
end
