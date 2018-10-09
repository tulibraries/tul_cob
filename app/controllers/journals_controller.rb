# frozen_string_literal: true

require "twilio-ruby"

class JournalsController < CatalogController
  configure_blacklight do |config|
    config.search_builder_class = JournalsSearchBuilder
    config.document_model = SolrJournalDocument
  end
end
