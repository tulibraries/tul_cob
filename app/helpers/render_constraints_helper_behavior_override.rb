# frozen_string_literal: true

module RenderConstraintsHelperBehaviorOverride
  ##
  # Overridden from module RenderConstraintsHelperBehavior.
  #
  # Overridden in order to disable rendering unknown facet fields.
  ##
  def render_filter_element(facet, values, path)
    return "" unless blacklight_config.facet_fields.map { |k, v|
      v.pivot ? v.pivot : k }.flatten.include? facet.to_s
    super(facet, values, path)
  end
end
