# frozen_string_literal: true

class SolrDocument
  include Blacklight::Solr::Document::RisFields
  include Citable
  include JsonLogger
  include Diggable
  include QueryListable
  include Lookupable
  include Blacklight::Solr::Document

  attr_accessor :logger

  def initialize(doc, req = nil)
    @libkey_journals_url_thread = libkey_journals_url_thread(doc)

    super

    if is_suppressed?
      raise Blacklight::Exceptions::RecordNotFound
    end
  end

  use_extension(Blacklight::Solr::Document::RisExport)

  # self.unique_key = "id"
  field_semantics.merge!(
    title: "title_statement_display" ,
    imprint: "imprint_display",
    production: "imprint_prod_display",
    distribution: "imprint_dist_display",
    manufacture: "imprint_man_display",
    author: "creator_display",
    contributor: "contributor_display",
    isbn: "isbn_display",
    issn: "issn_display",
    language: "language_display",
    format: "format",
    alma_mms: "alma_mms_display"
  )

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(LibrarySearch::Document::Email)

  # Add Blacklight-Marc extension:
  SolrDocument.use_extension(Blacklight::Marc::DocumentExtension) do |doc|
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

  def document_items
    document_items = fetch("items_json_display", [])
    document_items.collect { |item| item }
      .reject(&:blank?)
      .reject { |item| missing_or_lost?(item) }
      .reject { |item| unwanted_library_locations(item) }
      .each { |item| item.merge! ({ library: library_name_from_short_code(library(item)) }) }
      .each { |item| item.merge! ({ location: location_name_from_short_codes(location(item), library(item)) }) }
      .each { |item| item.merge! ({ call_number_display: alternative_call_number(item) }) }
  end

  def document_items_grouped
    grouped_items = document_items
      .group_by { |item| item["library"] }
      .transform_values { |library| library.group_by { |item| item["location"] }.sort.to_h }
    sorted_items = grouped_items
      .sort_by { |library, locations| [library == "Charles Library" ? 0 : 1, library] }.to_h
      .each do |library, locations|
        unless locations.empty?
          locations.each do |location, items|
            unless items.empty?
              items.sort_by! { |item| [item["call_number_display"], item.fetch("description", "")] }
            end
          end
        end
      end
  end

  def library(item)
    item["current_library"] ? item["current_library"] : item["permanent_library"]
  end

  def location(item)
    item["current_location"] ? item["current_location"] : item["permanent_location"]
  end

  def call_number(item)
    item["temp_call_number"] ? item["temp_call_number"] : item["call_number"]
  end

  def alternative_call_number(item)
    item["alt_call_number"] ? item["alt_call_number"] : call_number(item)
  end

  def libkey_journals_url
    @libkey_journals_url_thread.value&.fetch("browzineWebLink", nil)
  end

  def libkey_journals_url_enabled?
    @libkey_journals_url_thread.value&.fetch("browzineEnabled", nil) == true
  end

  private

    def libkey_journals_url_thread(doc)
      issn = doc.fetch("issn_display", []).map { |x| x.delete("-") }.uniq.join(",")
      return Thread.new {} if issn.empty?

      base_url = Rails.configuration.bento&.dig(:libkey, :base_url)
      library_id = Rails.configuration.bento&.dig(:libkey, :library_id)
      access_token = Rails.configuration.bento&.dig(:libkey, :apikey)
      libkey_journals_url = "#{base_url}/#{library_id}/search?issns=#{issn}&access_token=#{access_token}"
      Thread.new {
        (HTTParty.get(libkey_journals_url, timeout: 2) rescue {})["data"]&.first
          &.slice("browzineEnabled", "browzineWebLink")
      }
    end

    def logger
      @logger ||= Blacklight.logger
    end

    def missing_or_lost?(item)
      process_type = item.fetch("process_type", "")
      !!process_type.match(/MISSING|LOST_LOAN|LOST_LOAN_AND_PAID/)
    end

    def unwanted_library_locations(item)
      library = library(item) || ""
      location = location(item) || ""
      !!location.match(/techserv|UNASSIGNED|intref/) || library == "EMPTY"
    end
end
