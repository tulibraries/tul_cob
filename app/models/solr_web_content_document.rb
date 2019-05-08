# frozen_string_literal: true

class SolrWebContentDocument < SolrDocument
  use_extension(Blacklight::Document::Email)
  use_extension(Blacklight::Document::Sms)
end
