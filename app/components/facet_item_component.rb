# coding: utf-8
# frozen_string_literal: true

class FacetItemComponent < Blacklight::FacetItemComponent
  # Overrides Blacklight method to allow facet icons to be displayed
  def render_facet_value
    content_tag(:span, class: "facet-label") do
      link_to_unless(@suppress_link, @label, @href, class: "facet_select facet_#{@facet_item.facet_item.value.downcase.parameterize.underscore}")
    end + render_facet_count
  end

  def render_selected_facet_value
    content_tag(:span, class: "facet-label") do
        content_tag(:span, @label, class: "selected") +
          # remove link
          link_to(@href, class: "remove") do
            content_tag(:span, "", class: "remove-icon") +
              content_tag(:span, "[remove]", class: "sr-only")
          end
      end + render_facet_count(classes: ["selected"])
  end
end
