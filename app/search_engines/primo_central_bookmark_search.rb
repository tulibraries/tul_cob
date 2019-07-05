# frozen_string_literal: true

class PrimoCentralBookmarkSearch < PrimoCentralController
  include Searcher
  include BookmarksConfig

  self.search_service_class = PrimoSearchService

  def self.handle_bookmark_search?(document_model)
    blacklight_config.document_model == document_model
  end
end
