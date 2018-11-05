# frozen_string_literal: true

require "twilio-ruby"

class JournalsController < CatalogController
  add_breadcrumb "Journals", :back_to_journals_path, only: [ :show ]
  add_breadcrumb "Journal", :solr_journal_document_path, only: [ :show ]

  configure_blacklight do |config|
    config.search_builder_class = JournalsSearchBuilder
    config.document_model = SolrJournalDocument
    # Do not allow any further filtering on type.
    config.facet_fields.delete("format")
  end
end
