# frozen_string_literal: true

class CatalogBookmarkSearch < CatalogController
  include Searcher

  delegate :blacklight_config, to: CatalogController
end
