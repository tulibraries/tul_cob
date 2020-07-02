# frozen_string_literal: true

class FacetItemComponent < Blacklight::FacetItemComponent
  with_collection_parameter :facet_item

  # Overrides Blacklight method to allow facet icons to be displayed
  def render_facet_value
    content_tag(:span, class: "facet-label") do
      link_to_unless(@suppress_link, @label, @href, class: "facet_select facet_#{@facet_item.label.downcase.parameterize.underscore}")
    end + render_facet_count
  end
end
