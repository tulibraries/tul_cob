# frozen_string_literal: true

class JournalsAdvancedController < AdvancedController
  copy_blacklight_config_from(JournalsController)

  protected
    def search_action_url(options = {})
      journals_advanced_search_path(options.merge(action: "index"))
    end
end
