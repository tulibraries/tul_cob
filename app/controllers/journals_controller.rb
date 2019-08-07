# frozen_string_literal: true

class JournalsController < CatalogController
  configure_blacklight do |config|
    config.show.route = { controller: "journals" }
    config.search_builder_class = JournalsSearchBuilder
    config.document_model = SolrJournalDocument
    # Do not allow any further filtering on type.
    config.facet_fields.delete("format")
  end
end
