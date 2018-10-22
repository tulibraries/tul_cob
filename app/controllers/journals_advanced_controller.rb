# frozen_string_literal: true

class JournalsAdvancedController < AdvancedController
  copy_blacklight_config_from(JournalsController)

  add_breadcrumb "Journals", :back_to_journals_path
  add_breadcrumb I18n.t(:journals_advanced_search), :journals_advanced_search_path,
    only: [ :index ]

  protected
    def search_action_url(options = {})
      journals_advanced_search_path(options.merge(action: "index"))
    end
end
