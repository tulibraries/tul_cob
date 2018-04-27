# frozen_string_literal: true

module Blacklight::PrimoCentral::Document
  extend ActiveSupport::Concern
  include Blacklight::Document
  include Blacklight::Document::ActiveModelShim
  include Blacklight::PrimoCentral::SolrAdaptor

  def initialize(doc, req = nil)
    @url = url(doc)
    @url_query = url_query
    format = doc["@TYPE"] || doc["type"]
    # Dots and slahes break links to articles.
    doc[:pnxId] = doc[:pnxId].gsub(".", "-dot-") if doc[:pnxId]
    doc[:pnxId] = doc[:pnxId].gsub("/", "-slash-") if doc[:pnxId]
    doc["type"] = [format]
    doc["format"] = [format]
    doc["link"] = @url
    doc["link_label"] = link_label(doc)
    doc["isbn"] ||= isbn
    doc["lccn"] ||= lccn

    solr_to_primo_keys.each do |solr_key, primo_key|
      doc[solr_key] = doc[primo_key] || FIELD_DEFAULT_VALUES[primo_key]
    end

    super(doc, req)
  end

  def has_direct_link?
    availability = @_source.dig("delivery", "availability") || []
    availability == ["fulltext_linktorsrc"]
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
      get_it(doc).fetch("displayText", "Direct Link")
        .gsub("$$E", "")
        .gsub("_", " ")
    end

    def get_it(doc)
      doc.to_h.dig("delivery", "GetIt1", 0, "links", 0) || {}
    end


    def url_query
      query = URI.parse(@url).query
      if (query)
        CGI.parse(query) || {}
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
end
