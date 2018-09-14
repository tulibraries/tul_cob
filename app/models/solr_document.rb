# frozen_string_literal: true

class SolrDocument
  include Blacklight::Solr::Document
  include Blacklight::Solr::Document::RisFields

  use_extension(Blacklight::Solr::Document::RisExport)

  # self.unique_key = "id"
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
    location: "location_display",
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
  # the boundwith IDs, because that"s where Alma stores the holdings.
  def alma_availability_mms_ids
    fetch("bound_with_ids", [id])
  end

  def initialize(doc, req = nil)
    doc[:title_truncated_display] ||= doc[:title_statement_display]
      &.map { |t| t.truncate(300, separator: " ") }
    super doc, req
  end

  ris_field_mappings.merge!(
    TY: Proc.new {
      format = fetch("format", [])
      if format.member?("Book")
        "BOOK"
      elsif format.member?("Journal/Periodical")
        "JOUR"
      else
        "GEN"
      end
    },
    TI: "title_statement_display",
    ID: "alma_mms_display",
    AU: "creator_display",
    A2: "contributor_display",
    PY: "date_copyright_display",
    PB: "imprint_display",
    ET: "edition_display",
    LA: "language_display",
    KW: "subject_display",
    SN: "isbn_display",
    SN: "issn_display",
    CN: "call_number_display"
  )
end
