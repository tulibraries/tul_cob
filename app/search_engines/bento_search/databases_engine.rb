# frozen_string_literal: true

module BentoSearch
  class DatabasesEngine < BlacklightEngine
    delegate :blacklight_config, to: DatabasesController

    def doc_link(id)
      Rails.application.routes.url_helpers.solr_database_document_path(id)
    end

    def url(helper)
      params = helper.params
      helper.search_databases_path(q: params[:q])
    end

    def view_link(total = nil, helper)
      url = url(helper)
      helper.link_to "View all #{total} databases", url, class: "full-results"
    end
  end
end
