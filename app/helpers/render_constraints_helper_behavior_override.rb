# frozen_string_literal: true

module RenderConstraintsHelperBehaviorOverride
  ##
  # Overridden from module RenderConstraintsHelperBehavior.
  #
  # Overridden in order to disable rendering unknown facet fields.
  ##
  def render_filter_element(facet, values, search_state)
    return "" if blacklight_config.facet_fields[facet.to_s].blank?
    super(facet, values, search_state)
  end
end
