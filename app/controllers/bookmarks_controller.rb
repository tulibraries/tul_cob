# frozen_string_literal: true

# This will eventually be ported to an engine.
class BookmarksController < CatalogController
  include Blacklight::Bookmarks
  include MultiSourceBookmarks
  include BookmarksConfig


  def export_articles
    bookmarks = current_or_guest_user.bookmarks
      .where(document_type: "PrimoCentralDocument")

    urls = bookmarks
      .map { |b| "https://librarysearch.temple.edu/articles/#{b.document_id}" }

    bookmarks.update_all("title = 'exported'")

    send_data urls.join("\n"), filename: "article_bookmark_urls.txt"
  end
end
