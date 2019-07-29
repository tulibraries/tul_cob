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
      params = helper.params
      helper.search_web_content_path(q: params[:q])
    end

    def content_type(item)
      unless item["web_content_type_t"].nil?
        "Type: " + item["web_content_type_t"].first
      end
    end

    def view_link(total = nil, helper)
      url = url(helper)
      helper.link_to "View all website results", url, class: "full-results"
    end
  end
end
