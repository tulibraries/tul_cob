# frozen_string_literal: true

class SolrDocument
  include Blacklight::Solr::Document

  # self.unique_key = 'id'
  field_semantics.merge!(
    title: "title_statement_display" ,
    imprint: "imprint_display",
    author: "creator_display",
    contributor: "contributor_display",
    isbn: "isbn_display",
    issn: "issn_display",
    language: "language_display",
    format: "format",
    alma_mms: "alma_mms_display",
  )

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # Add Blacklight-Marc extension:
  SolrDocument.use_extension(Blacklight::Solr::Document::Marc) do |doc|
    doc.has_field? "marc_display_raw"
  end
  SolrDocument.extension_parameters[:marc_source_field] = "marc_display_raw"
  SolrDocument.extension_parameters[:marc_format_type] = :marcxml

  # used by blacklight_alma

  # returns an array of IDs to query through API to get holdings
  # for this document. This is usually just the alma MMS ID for
  # this bib record, but in the case of boundwith records, we return
  # the boundwith IDs, because that's where Alma stores the holdings.
  def alma_availability_mms_ids
    fetch("bound_with_ids", [id])
  end
end
