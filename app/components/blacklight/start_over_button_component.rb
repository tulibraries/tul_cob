# frozen_string_literal: true

module Blacklight
  class StartOverButtonComponent < Blacklight::Component
    def call
      link_to t("blacklight.search.start_over"),
              helpers.bento_search_engine_path,
              id: "start_over",
              class: "btn text-white"
    end
  end
end
