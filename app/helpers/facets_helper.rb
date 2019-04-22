# frozen_string_literal: true

module FacetsHelper
  include Blacklight::FacetsHelperBehavior

  def render_home_facets
    render_facet_partials home_facets
  end

  def home_facets
    blacklight_config.facet_fields.select { |_, v| v[:home] }.keys
  end

  # Overrides Blacklight method to allow facet icons to be displayed
  def render_facet_value(facet_field, item, options = {})
    path = path_for_facet(facet_field, item)

    html_options = { class: "facet_select facet_" + item.value.downcase.parameterize.underscore }

    content_tag(:span, class: "facet-label") do
      link_to_unless(options[:suppress_link], facet_display_value(facet_field, item), path, html_options)
    end + render_facet_count(item.hits, html_options)
  end

  def render_bento_format_facet_value(item, options = {})
    path = path_for_facet("format", item)

    html_options = { class: "facet_select facet_" + item.value.downcase.parameterize.underscore }

    if item.value == "digital_collections"
      html_options.merge!(target: "_blank")
    end

    content_tag(:span, class: "facet-label") do
      link_to_unless(options[:suppress_link], facet_display_value("format", item), path, html_options)
    end + " (#{item.hits})"
  end


  def render_selected_facet_value(facet_field, item)
    remove_href = search_action_path(search_state.remove_facet_params(facet_field, item))
    content_tag(:span, class: "facet-label") do
      content_tag(:span, facet_display_value(facet_field, item), class: "selected " + item.value.downcase.parameterize.underscore) +
      # remove link
      link_to(remove_href, class: "remove") do
        content_tag(:span, "", class: "remove-icon") +
        content_tag(:span, "[remove]", class: "sr-only")
      end
    end + render_facet_count(item.hits, classes: ["selected"])
  end
end
