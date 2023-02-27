# frozen_string_literal: true

class SolrWebContentDocument < SolrDocument
  use_extension(LibrarySearch::Document::Email)
end
