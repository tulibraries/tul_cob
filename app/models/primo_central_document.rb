# frozen_string_literal: true

class PrimoCentralDocument
  require "blacklight/primo_central"

  include Blacklight::PrimoCentral::Document
  include Blacklight::Configurable
  include PrimoFieldsConfig

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
end
