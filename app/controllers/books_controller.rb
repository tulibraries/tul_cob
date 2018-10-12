# frozen_string_literal: true

class BooksController < CatalogController
  configure_blacklight do |config|
    config.search_builder_class = BooksSearchBuilder
    config.document_model = ::SolrBookDocument
  end
end
