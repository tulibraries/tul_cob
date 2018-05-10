# frozen_string_literal: true

# This will eventually be ported to an engine.
class BookmarksController < CatalogController
  include Blacklight::Bookmarks
  include MultiSourceBookmarks
end
