# frozen_string_literal: true

class ClassificationFieldPresenter < Blacklight::FacetFieldPresenter
  def active?
    lc_begin = search_state.dig("range", "lc_classification", "begin")
    lc_end = search_state.dig("range", "lc_classification", "end")

    lc_begin.present? || lc_end.present? || super
  end

  def collapsed?
    super && !active?
  end
end
