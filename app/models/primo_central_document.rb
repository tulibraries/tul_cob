# frozen_string_literal: true

class PrimoCentralDocument
  require "blacklight/primo_central"

  include Blacklight::PrimoCentral::Document
  include Citable

  # Email uses semantic field mappings below to generate the body of an email.
  self.unique_key = :pnxId
  field_semantics.merge!(
    title: "title" ,
    part_of: "isPartOf",
    author: "creator",
    contributor: "contributor",
    date: "date",
    isbn: "isbn",
    issn: "issn",
    doi: "doi",
  )

  use_extension Blacklight::PrimoCentral::DocumentExport
  use_extension Blacklight::Document::ArticleEmail
  use_extension Blacklight::Document::Sms

  include Blacklight::Solr::Document::RisFields
  use_extension(Blacklight::Solr::Document::RisExport)

  ris_field_mappings.merge!(
    TY: Proc.new {
      format = fetch("format", [])
      if format.member?("Book")
        "BOOK"
      elsif format.member?("article")
        "JOUR"
      else
        "GEN"
      end
    },
    TI: "title",
    ID: "pnxId",
    A1: "creator",
    A2: "contributor",
    PB: "publisher",
    Y1: "date",
    JF: "isPartOf",
    AB: "description",
    DO: "doi",
    KW: "subject",
    SN: Proc.new { self["isbn"] || self["issn"] },
    SN: "issn",
    LA: "languageId"
  )
end
