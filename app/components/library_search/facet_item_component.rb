# frozen_string_literal: true

module LibrarySearch
  class FacetItemComponent < Blacklight::Facets::ItemComponent
    ##
    # Overrides Blacklight::Facets::ItemComponent.render_facet_value
    #
    # @return [String]
    # @private
    def render_facet_value
      tag.span(class: "facet-label") do
        link_to_unless(@suppress_link, label, href, class: "facet-select facet_#{label.downcase.parameterize.underscore}", rel: "nofollow")
      end + render_facet_count
    end

    ##
    # Overrides Blacklight::Facets::ItemComponent.render_selected_facet_value
    #
    # @private
    def render_selected_facet_value
      concat render(LibrarySearch::FacetSelectedValueComponent.new(label: label, href: href))
      concat render_facet_count(classes: ["selected"])
    end
  end
end
