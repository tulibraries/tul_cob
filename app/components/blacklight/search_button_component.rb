# frozen_string_literal: true

module Blacklight
  class SearchButtonComponent < ::ViewComponent::Base
    def initialize(text:, id:)
      @text = nil
      @id = id
    end

    def call
      tag.button(class: "btn btn-royal-blue search-btn border-royal-blue", type: "submit", id: @id) do
        tag.span(@text, class: "submit-search-text") +
        tag.i(class: "fa fa-search")
      end
    end
  end
end
