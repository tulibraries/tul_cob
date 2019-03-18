# frozen_string_literal: true

class JournalsController < CatalogController
  add_breadcrumb "Journals", :back_to_journals_path, options: { id: "breadcrumbs_journal" }, only: [ :show ]
  add_breadcrumb "Record", :solr_journal_document_path, only: [ :show ]

  configure_blacklight do |config|
    config.show.route = { controller: "journals" }
    config.search_builder_class = JournalsSearchBuilder
    config.document_model = SolrJournalDocument
    # Do not allow any further filtering on type.
    config.facet_fields.delete("format")
  end
end
