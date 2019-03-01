# frozen_string_literal: true

namespace :bookmarks do
  desc "Updates to boomark data."

  task update_bookmark_document_type: :environment do
    bookmarks = Bookmark.where("document_type LIKE ?", "Solr%Document")

    puts "Going to update #{bookmarks.count} bookmarks"

    ActiveRecord::Base.transaction do
      bookmarks.update(document_type: "SolrDocument")
    end

    puts "Finished updating bookmarks."
  end
end
