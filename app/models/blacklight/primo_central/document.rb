# frozen_string_literal: true

module Blacklight::PrimoCentral::Document
  extend ActiveSupport::Concern
  include Blacklight::Document
  include Blacklight::Document::ActiveModelShim
  include Blacklight::PrimoCentral::SolrAdaptor

  def initialize(doc, req = nil)
    format = doc["@TYPE"] || doc["type"]
    doc["format"] = [format]
    url = doc["delivery"]["GetIt1"]
      .first["links"]
      .first["link"]

    # dots do not get URL encoded and break links to articles.
    doc[:pnxId] = doc[:pnxId].gsub(".", "-dot-") if doc[:pnxId]

    doc["link"] = url

    solr_to_primo_keys.each do |solr_key, primo_key|
      doc[solr_key] = doc[primo_key] || FIELD_DEFAULT_VALUES[primo_key]
    end

    super(doc, req)
  end

  private

    FIELD_DEFAULT_VALUES = {
      "isbn" => "",
      "issn" => "",
      "lccn" => "",
    }
end
