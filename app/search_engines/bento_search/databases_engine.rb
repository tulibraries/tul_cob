# frozen_string_literal: true

module BentoSearch
  class DatabasesEngine < BlacklightEngine
    delegate :blacklight_config, :search_service_class, to: DatabasesController

    def doc_link(id)
      Rails.application.routes.url_helpers.solr_database_document_path(id)
    end

    def url(helper)
      params = helper.params.slice(:q)
      helper.search_databases_path(params)
    end

    def view_link(total = nil, helper)
      url = url(helper)
      link_text = Flipflop.style_updates? ? "See all #{total} results" : "View all #{total} results"
      helper.link_to link_text, url, class: "bento-full-results bento_databases_header"
    end
  end
end
