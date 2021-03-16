# frozen_string_literal: true

class PivotFacetFieldPresenter < Blacklight::FacetFieldPresenter
  def active?
    return true if facet_field.pivot.find { |_key| view_context.facet_field_in_params?(_key) }
  end

  def collapsed?
    return !active?
  end
end
