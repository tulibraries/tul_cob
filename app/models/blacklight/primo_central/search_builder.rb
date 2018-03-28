# frozen_string_literal: true

module Blacklight::PrimoCentral
  class SearchBuilder < Blacklight::SearchBuilder
    include Blacklight::PrimoCentral::SearchBuilderBehavior
    include Blacklight::PrimoCentral::SolrAdaptor
  end
end
