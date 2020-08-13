# frozen_string_literal: true

class SolrDocument
  include Blacklight::Solr::Document
  include Blacklight::Solr::Document::RisFields
  include AvailabilityHelper
  include Citable
  include JsonLogger
  include Diggable

  attr_accessor :logger

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
    alma_mms: "alma_mms_display"
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
    doc[:materials_data] = materials_data

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
    Y1: "date_copyright_display",
    PB: "imprint_display",
    ET: "edition_display",
    LA: "language_display",
    KW: "subject_display",
    SN: Proc.new { self["isbn_display"] || self["issn_display"] },
    CN: "call_number_display"
  )

  def materials_data
    Proc.new {
      @materials_data ||= alma_availability_mms_ids.map { |id|
        # return maximum allowed item or lose items.
        log = { type: "alma_bib_item", mms_id: id, limit: 100 }
        do_with_json_logger(log) { Alma::BibItem.find(id, limit: 100).filter_missing_and_lost }
      }.first
    }
  end

  # Loads a list of books or other physical materials assoc. to record.
  # (As apposed to an online only item)
  def materials
    @materials ||= materials_data[]
      .map { |material|
      { title: material["bib_data"]["title"],
        barcode: barcode(material),
        call_number: material["holding_data"]["call_number"],
        library: library_name_from_short_code(material.library),
        location: location_status(material),
        availability: availability_status(material) }
        .with_indifferent_access }
        .uniq { |material| material.except(:barcode) }
  end

  def material_from_barcode(barcode = nil)
    materials.select { |material| material[:barcode] == barcode }.first
  end

  def barcodes
    materials.map { |material| material[:barcode] }
  end

  def valid_barcode?(barcode = nil)
    barcodes.include? barcode
  end

  def purchase_order?
    !!self["purchase_order"]
  end

  def is_suppressed?
    fetch("suppress_items_b", false)
  end

  def merge_item_data!(additional_item_data)
    fetch("items_json_display", []).each do |item|
      next unless additional_item_data.has_key? item["item_pid"]
      item.merge!(additional_item_data[item["item_pid"]])
    end
  end

  private
    def barcode(item)
      item["item_data"]["pid"]
    end

    def availability_status(item)
      if item.in_place? && item.non_circulating?
        "Library Use Only"
      elsif item.in_place?
        "Available"
      elsif item.has_process_type?
        Rails.configuration.process_types[item.process_type] ||
          "Checked out or currently unavailable"
      else
        "Checked out or currently unavailable"
      end
    end

    def logger
      @logger ||= Blacklight.logger
    end
end
