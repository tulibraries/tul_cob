# frozen_string_literal: true

module FacetsHelper
  include Blacklight::FacetsHelperBehavior

  def facet_item_component_class(facet_config)
    return FacetItemPivotComponent if facet_config.pivot
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


  def locations_map
    @locations_map ||= Rails.configuration.locations.values.inject(&:merge)
  end

  def library_location_label(value, include_library = false)
    library, label = value.split(" - ")
    label = locations_map[label] || label

    if include_library
      [library, label].join(" - ")
    else
      label
    end
  end

  def pre_process_library_facet!(item)
    # Filter out secondary facets that do not match library
    item.items.select! { |i| i.value.match?(/#{item.value}/) }

    # Add propper secondary facet labels
    item.items.each { |i| i.label = library_location_label(i.value) }
  end


  ##
  # Overridden to allow pivot sub fields to be rendered in 'selected' state
  # and pre process the "library_pivot_facet" field.
  #
  def render_facet_item(facet_field, item)
    if facet_field == "library_pivot_facet"
      pre_process_library_facet!(item)
    end

    facet_config = facet_configuration_for_field(facet_field)
    if facet_config.pivot
      facet_config.pivot.find { |pivot_facet_field|
        pivot_facet_field == item.field
      }.tap { |inner_field|
        return render_facet_item(inner_field, item)
      }
    # remove :indefinite_facet_count to restore default facet count display for outer pivot facets that
    #  have a selected inner facet
    elsif item.items && item.items.size == 1 && facet_field_in_params?(item.items[0].field) &&
          params["f"][item.items[0].field] &&
          params["f"][item.items[0].field].include?(item.items[0].value)
      facet_item_component(facet_config, item, facet_field, hide_facet_param: item.items[0]).render_facet_value(indefinite_facet_count: true)
    else
      super
    end
  end

  # Add an option to the core method that allows us to force remove params from
  # the presenter's href constructing methods, so that we can eliminate redundant
  # pivot fields.
  def facet_item_component(facet_config, facet_item, facet_field, **args)
    presenter = facet_item_presenter(facet_config, facet_item, facet_field)
    if args[:hide_facet_param]
      presenter.hide_facet_param(args[:hide_facet_param])
      presenter.keep_in_params!
    end
    args.delete(:hide_facet_param)
    facet_item_component_class(facet_config).new(facet_item: presenter, **args).with_view_context(self)
  end

  def facet_item_presenter(facet_config, facet_item, facet_field)
    FacetItemPresenter.new(facet_item, facet_config, self, facet_field)
  end
end
