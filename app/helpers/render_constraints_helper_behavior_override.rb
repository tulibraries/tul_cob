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
end
