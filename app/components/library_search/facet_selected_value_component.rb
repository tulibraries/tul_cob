# frozen_string_literal: true

module LibrarySearch
  # Standard display of a selected facet value (e.g. without a link and with a remove button)
  class FacetSelectedValueComponent < Blacklight::Facets::SelectedValueComponent
    def call
      tag.span(class: "facet-label") do
        tag.span(label, class: "selected #{label.downcase.parameterize.underscore}") + remove_link
      end
    end
  end
end
