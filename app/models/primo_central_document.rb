# frozen_string_literal: true

class PrimoCentralDocument
  require "blacklight/primo_central"

  include Blacklight::PrimoCentral::Document

  self.unique_key = :pnxId
end
