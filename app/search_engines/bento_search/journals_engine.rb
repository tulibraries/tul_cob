# frozen_string_literal: true

module BentoSearch
  class JournalsEngine < BlacklightEngine
    delegate :blacklight_config, :search_service_class, to: JournalsController

    def doc_link(id)
      Rails.application.routes.url_helpers.solr_journal_document_path(id)
    end

    def url(helper)
      params = helper.params.slice(:q)
      helper.search_journals_path(params)
    end

    def view_link(total = nil, helper)
      url = url(helper)
      helper.link_to "View all #{total} journals", url, class: "bento-full-results"
    end
  end
end
