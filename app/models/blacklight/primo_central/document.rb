# frozen_string_literal: true

module Blacklight::PrimoCentral::Document
  extend ActiveSupport::Concern
  include Blacklight::Document
  include Blacklight::Document::ActiveModelShim
  include Blacklight::PrimoCentral::SolrAdaptor

  delegate :url_helpers, to: "Rails.application.routes"

  attr_reader :blacklight_config

  def initialize(doc, options = {})
    @url = url(doc)
    @url_query = url_query

    # Dots and slahes break links to articles.
    doc["pnxId"] ||= doc.dig("pnx", "search", "recordid")&.first
    doc["pnxId"] = doc["pnxId"]&.gsub(".", "-dot-")
    doc["pnxId"] = doc["pnxId"]&.gsub("/", "-slash-")
    doc["pnxId"] = doc["pnxId"]&.gsub(";", "-semicolon-")

    # Normalizes the primos/pnxs id to the primo/search id
    doc["pnxId"] = doc["pnxId"]&.gsub(/^TN_/, "")

    doc["description"] ||= doc.dig("pnx", "search", "description")&.first
    doc["subject"] ||= doc.dig("pnx", "search", "subject")

    format = doc["@TYPE"] || doc["type"] ||
      doc.dig("pnx", "display", "type")&.first || "unknown"
    doc["type"] = [format]
    doc["format"] = [format]

    doc["title"] ||= doc.dig("pnx", "display", "title")&.first&.truncate(300)
    doc["link"] = @url
    doc["link_label"] = link_label(doc)
    doc["isbn"] ||= doc.dig("pnx", "search", "isbn") || isbn
    doc["issn"] ||= doc.dig("pnx", "search", "issn") || issn
    doc["lccn"] ||= lccn

    doc["isPartOf"] ||= doc.dig("pnx", "display", "ispartof")&.first
    doc["creator"] ||= doc.dig("pnx", "search", "creatorcontrib") || []
    doc["date"] ||= doc.dig("pnx", "search", "creationdate") || []

    solr_to_primo_keys.each do |solr_key, primo_key|
      doc[solr_key] = doc[primo_key] || FIELD_DEFAULT_VALUES[primo_key]
    end

    @blacklight_config = options&.dig(:blacklight_config)
    super(doc, options)
  end

  def has_direct_link?
    availability = @_source.dig("delivery", "availability") || []
    availability == ["fulltext_linktorsrc"]
  end

  def ajax?
    (!!@_source["ajax"] || @_source["ajax"] == "true") rescue false
  end


  # Stimulus controller used for controlling ajax endpoint.
  def ajax_controller
    "index"
  end

  # Ajax endpoint for rendering this document.
  def ajax_url(count = 0)
    url_helpers.articles_index_item_path(@_source["pnxId"], document_counter: count)
  end

  def materials
    # There are no physical items assoc. to Primo articles.
    []
  end

  def material_from_barcode(b = nil)
    # There are no physical items assoc. to Primo articles.
  end


  private

    FIELD_DEFAULT_VALUES = {
      "isbn" => [],
      "issn" => [],
      "lccn" => [],
    }

    def url(doc)
      get_it(doc).fetch("link", "")
    end

    def link_label(doc)
      I18n.t("primo_central.link_to_resource")
    end

    def get_it(doc = nil)
      doc = (doc || @_source || {})
      doc.dig("delivery", "GetIt1", 0, "links", 0) || {}
    end


    def url_query
      query = (URI.parse(@url).query rescue nil)
      if (query)
        q = CGI.parse(query) || {}
        q.select { |k, v| v && !v.empty? && v != [""] }
      else
        {}
      end
    end

    def isbn
      @url_query["rft.isbn"]
    end

    def lccn
      @url_query["rft.lccn"]
    end

    def issn
      @url_query["rft.issn"]
    end
end
