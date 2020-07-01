# frozen_string_literal: true

module RenderConstraintsHelperBehaviorOverride
  ##
  # Overridden from module RenderConstraintsHelperBehavior.
  #
  # Overridden in order to disable rendering unknown facet fields.
  ##
  def render_filter_element(facet, values, path)
    facet_config = facet_configuration_for_field(facet)

    safe_join(Array(values).map do |val|
      next if val.blank? # skip empty string
      # skip if facet field not configured
      next if blacklight_config.facet_fields[facet.to_s].blank?
      render_constraint_element(facet_field_label(facet_config.key),
                                facet_display_value(facet, val),
                                remove: search_action_path(path.remove_facet_params(facet, val)),
                                classes: ["filter", "filter-" + facet.parameterize])
    end, "\n")
  end
  ##
  # Override with v7.5.0 version do to bug.
  #
  # @see https://github.com/projectblacklight/blacklight_range_limit/issues/152
  # #
  def render_constraints_filters(my_params = params)
    content = super(my_params)
    # add a constraint for ranges?
    if my_params.to_h[:range].present? && my_params.to_h[:range].respond_to?(:each_pair)
      my_params.to_h[:range].each_pair do |solr_field, hash|

        next unless hash["missing"] || (!hash["begin"].blank?) || (!hash["end"].blank?)
        content << render_constraint_element(
          facet_field_label(solr_field),
          range_display(solr_field, my_params),
          escape_value: false,
          remove: remove_range_param(solr_field, my_params)
        )
      end
    end
    return content
  end
end
