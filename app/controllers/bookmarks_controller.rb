# frozen_string_literal: true

class BookmarksController < CatalogController
  include Blacklight::Bookmarks

  # Overridden to not cache.
  def index
    no_cache
    super
  end
end
