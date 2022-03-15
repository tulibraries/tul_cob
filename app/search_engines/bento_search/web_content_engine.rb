# frozen_string_literal: true

module BentoSearch
  class WebContentEngine < BlacklightEngine
    delegate :blacklight_config, :search_service_class, to: WebContentController

    def conform_to_bento_result(item)
      BentoSearch::ResultItem.new(
        title: item["web_title_display"].first,
        publisher: content_type(item),
        link: solr_web_content_document_path(item, options = {}).first
      )
    end

    def solr_web_content_document_path(item, options = {})
      # web_link_display is used for highlights
      item["web_url_display"] || item["web_base_url_display"] || item.fetch("web_link_display", "#")
    end

    def url(helper)
      params = helper.params.slice(:q)
      helper.search_web_content_path(params)
    end

    def content_type(item)
      unless item["web_content_type_t"].nil?
        "Type: " + item["web_content_type_t"]
      end
    end

    def view_link(total = nil, helper)
      url = url(helper)
      helper.link_to "View all library website results", url, class: "bento-full-results"
    end
  end
end
