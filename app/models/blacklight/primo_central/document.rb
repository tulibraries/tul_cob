# frozen_string_literal: true

module Blacklight::PrimoCentral::Document
  extend ActiveSupport::Concern
  include Blacklight::Document
  include Blacklight::Document::ActiveModelShim
  include Blacklight::PrimoCentral::SolrAdaptor

  delegate :dig, :[], to: :@_source

  def []=(key, value)
    @_source = @_source.merge("#{key}": value)
  end


  attr_reader :blacklight_config

  def initialize(doc, options = {})
    @url = url(doc)
    @url_query = url_query

    # Dots and slahes break links to articles.
    doc["pnxId"] ||= doc.dig("pnx", "control", "recordid")&.first
    doc["pnxId"] = doc["pnxId"]&.gsub(".", "-dot-")
    doc["pnxId"] = doc["pnxId"]&.gsub("/", "-slash-")
    doc["pnxId"] = doc["pnxId"]&.gsub(";", "-semicolon-")

    # Normalizes the primos/pnxs id to the primo/search id
    doc["pnxId"] = doc["pnxId"]&.gsub(/^TN_/, "")

    doc["description"] ||= doc.dig("pnx", "search", "description")&.first
    doc["subject"] ||= doc.dig("pnx", "facets", "topic")
    doc["subject"] ||= doc.dig("pnx", "search", "subject")

    format = doc["@TYPE"] || doc["type"] ||
      doc.dig("pnx", "display", "type")&.first || "unknown"
    doc["type"] = [format]
    doc["format"] = [format]

    doc["title"] ||= doc.dig("pnx", "display", "title")&.first&.truncate(300)
    doc["contributor"] ||= doc.dig("pnx", "display", "contributor")&.first&.split(";")
    doc["publisher"] ||= doc.dig("pnx", "display", "publisher") ||
      doc.dig("pnx", "addata", "pub")
    doc["relation"] ||= doc.dig("pnx", "display", "relation")
    doc["link"] = @url
    doc["link_label"] = link_label(doc)
    doc["isbn"] ||= doc.dig("pnx", "search", "isbn") || isbn
    doc["issn"] ||= doc.dig("pnx", "search", "issn") || issn
    doc["lccn"] ||= doc.dig("pnx", "addata", "lccn") || lccn

    doc["isPartOf"] ||= doc.dig("pnx", "display", "ispartof")&.first
    doc["creator"] ||= doc.dig("pnx", "search", "creatorcontrib") || []

    doc["date"] ||= doc.dig("pnx", "search", "creationdate") || []

    doc["language"] = doc.dig("pnx", "search", "language") ||
      doc.dig("pnx", "display", "language") ||
      ([ doc["lang3"] ] if doc["lang3"])

    doc["doi"] = doc.dig("pnx", "addata", "doi")

    @doi = doc["doi"]&.first

    @libkey_url_thread = libkey_url_thread

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

  def materials
    # There are no physical items assoc. to Primo articles.
    []
  end

  def material_from_barcode(b = nil)
    # There are no physical items assoc. to Primo articles.
  end

  def purchase_order?
    # For now, disable all purchase orders for Primo documents.
    false
  end

  def libkey_url
    @libkey_url_thread.value&.values&.find(&:present?)
  end

  def libkey_url_retracted?
    @libkey_url_thread.value&.has_key?("retractionNoticeUrl")
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

    def libkey_url_thread
      return Thread.new {} if @doi.blank?

      access_token = Rails.configuration.bento&.dig(:libkey, :apikey)
      libkey_url = "https://public-api.thirdiron.com/public/v1/libraries/130/articles/doi/#{@doi}?access_token=#{access_token}"

      Thread.new {
        (HTTParty.get(libkey_url, timeout: 2) rescue {})["data"]
          &.slice("retractionNoticeUrl", "fullTextFile", "contentLocation")
      }
    end
end
