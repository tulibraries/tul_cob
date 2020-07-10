# frozen_string_literal: true

module FacetsHelper
  include Blacklight::FacetsHelperBehavior

  def facet_item_component_class(facet_config)
    default_component = FacetItemComponent
    facet_config.fetch(:item_component, default_component)
  end

  def render_home_facets
    render_facet_partials home_facets
  end

  def home_facets
    blacklight_config.facet_fields.select { |_, v| v[:home] }.keys
  end

  def render_bento_format_facet_value(item, options = {})
    facet_config = facet_configuration_for_field("format")
    facet_item_presenter = facet_item_presenter(facet_config, item, "format")
    path = facet_item_presenter.href(options)

    html_options = { class: "facet_select facet_" + item.value.downcase.parameterize.underscore }

    if item.value == "digital_collections"
      html_options.merge!(target: "_blank")
    end

    content_tag(:span, class: "facet-label") do
      link_to_unless(options[:suppress_link], facet_item_presenter.label, path, html_options)
    end + " (#{item.hits})"
  end

  # Can be removed when blacklight is upgraded to include this commit:
  # https://github.com/projectblacklight/blacklight/commit/2d80c91dbc6e728b61839bae7d3e6d33a6ca542e
  def render_facet_limit(display_facet, options = {})
    field_config = facet_configuration_for_field(display_facet.name)
    return if field_config.component && !should_render_field?(field_config, display_facet)
    super(display_facet, options)
  end
end
