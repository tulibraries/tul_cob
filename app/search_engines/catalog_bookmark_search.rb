# frozen_string_literal: true

class CatalogBookmarkSearch < CatalogController
  include Searcher
  include BookmarksConfig
end
