# frozen_string_literal: true

# This will eventually be ported to an engine.
class BookmarksController < CatalogController
  include Blacklight::Bookmarks
  include MultiSourceBookmarks
  include BookmarksConfig

  configure_blacklight do |config|
    config.add_show_tools_partial(:ris, label: "RIS File", modal: false, path: :ris_path)
  end
end
