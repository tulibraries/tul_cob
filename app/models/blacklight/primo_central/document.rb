# frozen_string_literal: true

module Blacklight::PrimoCentral::Document
  extend ActiveSupport::Concern
  include Blacklight::Document
  include Blacklight::Document::ActiveModelShim
  include Blacklight::PrimoCentral::SolrAdaptor

  delegate :url_helpers, to: "Rails.application.routes"

  def initialize(doc, req = nil)
    @url = url(doc)
    @url_query = url_query
    format = doc["@TYPE"] || doc["type"] || "unknown"
    # Dots and slahes break links to articles.
    doc["pnxId"] = doc["pnxId"]&.gsub(".", "-dot-")
    doc["pnxId"] = doc["pnxId"]&.gsub("/", "-slash-")
    doc["pnxId"] = doc["pnxId"]&.gsub(";", "-semicolon-")
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
end
