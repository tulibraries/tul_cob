# frozen_string_literal: true

class SolrWebContentDocument < SolrDocument
  use_extension(LibrarySearch::Document::Email)
  use_extension(LibrarySearch::Document::Sms)
end
