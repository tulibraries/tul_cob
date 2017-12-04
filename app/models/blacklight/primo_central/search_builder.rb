module Blacklight::PrimoCentral
  class SearchBuilder < Blacklight::SearchBuilder
    include Blacklight::PrimoCentral::SearchBuilderBehavior
  end
end
