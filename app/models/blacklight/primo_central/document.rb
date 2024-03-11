# frozen_string_literal: true

require "pry"

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
    @libkey_articles_url_thread = libkey_articles_url_thread

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

  def libkey_articles_url
    @libkey_articles_url_thread.value&.values&.find(&:present?)
  end

  def libkey_articles_url_retracted?
    @libkey_articles_url_thread.value&.has_key?("retractionNoticeUrl")
  end


  private

    FIELD_DEFAULT_VALUES = {
      "isbn" => [],
      "issn" => [],
      "lccn" => [],
    }

    def url(doc)
      # Direct Link to Resource
      directlink = doc.dig("pnx", "links", "linktorsrc", 0)
      # Alma Openurl
      almaopenurl = doc.dig("delivery", "almaOpenurl") || {}

      if directlink.present?
        url = directlink.split("$$").select { |substring| substring.start_with?("U") }.join[1..-1]

        if url.present? && !url&.match?(/libproxy/) && !is_oa?(doc)
          url = "https://libproxy.temple.edu/login?url=" + url
        elsif url.nil?
          almaopenurl
        else
          url
        end

      else
        almaopenurl
      end
    end

    def is_oa?(doc)
      doc.dig("pnx", "addata", "oa").present?
    end

    def link_label(doc)
      I18n.t("primo_central.link_to_resource")
    end

    def url_query(url = @url)
      query = (URI.parse(url).query rescue nil)
      if (query)
        q = CGI.parse(query) || {}

        if q["url"].present?
          return url_query(q["url"].first)
        end
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

    def libkey_articles_url_thread
      return Thread.new {} if @doi.blank?

      base_url = Rails.configuration.bento&.dig(:libkey, :base_url)
      library_id = Rails.configuration.bento&.dig(:libkey, :library_id)
      access_token = Rails.configuration.bento&.dig(:libkey, :apikey)
      libkey_articles_url = "#{base_url}/#{library_id}/articles/doi/#{@doi}?access_token=#{access_token}"

      Thread.new {
        begin
          HTTParty.get(libkey_articles_url, timeout: 4)["data"]
            &.slice("retractionNoticeUrl", "fullTextFile", "contentLocation")
        rescue => e
          Honeybadger.notify(e)
          nil
        end
      }
    end
end
