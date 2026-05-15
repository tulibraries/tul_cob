# frozen_string_literal: true

module LibrarySearch
  class SearchButtonComponent < Blacklight::SearchButtonComponent
    def call
      tag.button(class: "btn btn-royal-blue search-btn border-royal-blue", type: "submit", id: @id) do
        tag.span(nil, class: "submit-search-text") +
          tag.i(class: "fa fa-search")
      end
    end
  end
end
