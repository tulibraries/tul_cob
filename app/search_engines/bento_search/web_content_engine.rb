# frozen_string_literal: true

module BentoSearch
  class WebContentEngine < BlacklightEngine
    delegate :blacklight_config, :search_service_class, to: WebContentController

    def conform_to_bento_result(item)
      BentoSearch::ResultItem.new(
        title: item["web_title_display"].to_s.gsub(/[^a-z0-9]/i, "")
      )
    end

    def doc_link(id)
    end

    def url(helper)
      params = helper.params
      helper.search_web_content_path(q: params[:q])
    end

    def view_link(total = nil, helper)
      url = url(helper)
      helper.link_to "View all website results", url, class: "full-results"
    end
  end
end
