# frozen_string_literal: true

class PivotFacetFieldPresenter < Blacklight::FacetFieldPresenter
  def active?
    facet_field.pivot.find { |_key|
      config = view_context.facet_configuration_for_field(_key)
      search_state.filter(config).any?
    }.present?
  end

  def collapsed?
    return !active?
  end
end
