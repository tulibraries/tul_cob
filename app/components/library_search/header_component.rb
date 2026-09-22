# frozen_string_literal: true

module LibrarySearch
  class HeaderComponent < Blacklight::Component
    def initialize(blacklight_config:)
      @blacklight_config = blacklight_config
    end

    attr_reader :blacklight_config
  end
end
