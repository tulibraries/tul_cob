# frozen_string_literal: true

class FacetItemComponent < Blacklight::FacetItemComponent
  def overridden_helper_methods?
    return false
  end

  # Overrides Blacklight method to allow facet icons to be displayed
  def render_facet_value(options = {})
    options[:indefinite_facet_count] = @facet_item.has_selected_child?
    content_tag(:span, class: "facet-label") do
      link_to_unless(@suppress_link, @label, @href, class: "facet_select facet_#{@facet_item.facet_item.value.downcase.parameterize.underscore}")
    end + render_facet_count(options)
  end

  def render_selected_facet_value
    return render_facet_value if @facet_item.has_selected_child?
    content_tag(:span, class: "facet-label") do
        content_tag(:span, @label, class: "selected #{@facet_item.facet_item.value.downcase.parameterize.underscore}") +
          # remove link
          link_to(@href, class: "remove") do
            content_tag(:span, "", class: "remove-icon") +
              content_tag(:span, "[remove]", class: "sr-only")
          end
      end + render_facet_count(classes: ["selected"])
  end

  def render_facet_count(options = {})
    return super unless options[:indefinite_facet_count]

    classes = (options[:classes] || []) << "facet-count"
    content_tag("span", " ", class: classes)
  end
end
