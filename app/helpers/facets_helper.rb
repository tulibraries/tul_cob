# frozen_string_literal: true

module FacetsHelper
  include Blacklight::FacetsHelperBehavior

  def facet_item_component_class(facet_config)
    return super if facet_config.pivot
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

  def facet_field_presenter(facet_config, display_facet)
    return PivotFacetFieldPresenter.new(facet_config, display_facet, self) if facet_config.pivot
    super(facet_config, display_facet)
  end

  ##
  # Allows pivot sub fields to be rendered in 'selected' state
  #
  def render_facet_item(facet_field, item)
    facet_config = facet_configuration_for_field(facet_field)
    if facet_config.pivot
      facet_config.pivot.find { |pivot_facet_field|
        pivot_facet_field == item.field
      }.tap { |inner_field|
        return super(inner_field, item)
      }
    else
      super
    end
  end
end
