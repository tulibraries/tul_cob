# frozen_string_literal: true

class SolrBookDocument < SolrDocument
  use_extension(Blacklight::Document::Email)
  use_extension(Blacklight::Document::Sms)

  # Add Blacklight-Marc extension:
  SolrBookDocument.use_extension(Blacklight::Solr::Document::Marc) do |doc|
    doc.has_field? "marc_display_raw"
  end
  SolrBookDocument.extension_parameters[:marc_source_field] = "marc_display_raw"
  SolrBookDocument.extension_parameters[:marc_format_type] = :marcxml
end
