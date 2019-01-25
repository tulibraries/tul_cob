# frozen_string_literal: true

class SolrJournalDocument < SolrDocument
  use_extension(Blacklight::Document::Email)
  use_extension(Blacklight::Document::Sms)

  SolrJournalDocument.use_extension(Blacklight::Solr::Document::Marc) do |doc|
    doc.has_field? "marc_display_raw"
  end
  SolrJournalDocument.extension_parameters[:marc_source_field] = "marc_display_raw"
  SolrJournalDocument.extension_parameters[:marc_format_type] = :marcxml
end
