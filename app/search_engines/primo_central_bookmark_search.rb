# frozen_string_literal: true

class PrimoCentralBookmarkSearch < PrimoCentralController
  include Searcher

  delegate :blacklight_config, to: PrimoCentralController
end
