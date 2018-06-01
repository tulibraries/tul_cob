# frozen_string_literal: true

module Searcher
  def initialize(search_state = nil)
    @search_state = search_state ||
      Blacklight::SearchState.new(params, blacklight_config, self)
  end
end
