# frozen_string_literal: true

module Blacklight::Marc
  module Catalog
    extend ActiveSupport::Concern

    included do
      add_show_tools_partial(:staff_view)
    end

    def librarian_view
      super
      if @document.respond_to? :to_marc
        marc_view = render "marc_view", document: @document
        @marc_view = [ marc_view ]
      else
        @marc_view [ t("blacklight.search.librarian_view.empty") ]
      end
    end
  end
end
