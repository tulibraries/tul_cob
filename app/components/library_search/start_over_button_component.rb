# frozen_string_literal: true

module LibrarySearch
  class StartOverButtonComponent < Blacklight::StartOverButtonComponent
    def call
      link_to t("blacklight.search.start_over"),
              helpers.everything_start_over_path,
              id: "start_over",
              class: "btn text-white"
    end
  end
end
