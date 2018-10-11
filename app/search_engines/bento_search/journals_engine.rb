# frozen_string_literal: true

module BentoSearch
  class JournalsEngine < BlacklightEngine
    delegate :blacklight_config, to: JournalsController

    def url(helper)
      helper.search_journals_path(helper.params.except(:controller, :action))
    end

    def view_link(total = nil, helper)
      url = url(helper)
      helper.link_to "View all #{total} journals", url, class: "full-results"
    end
  end
end
