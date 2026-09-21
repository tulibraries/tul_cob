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
        link_to_unless(@suppress_link, label, href, class: facet_value_classes, rel: "nofollow")
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

    private

      def facet_value_classes
        classes = ["facet-select"]
        case @facet_item.facet_field.to_s
        when "format", "az_format", "rtype"
          classes << "facet_#{facet_item_value.downcase.parameterize.underscore}"
        end
        classes.join(" ")
      end

      def facet_item_value
        value = @facet_item.facet_item
        value.respond_to?(:value) ? value.value.to_s : label
      end
  end
end
