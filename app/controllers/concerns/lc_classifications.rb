# frozen_string_literal: true

module LCClassifications
  extend ActiveSupport::Concern

  def render_lc_call_number_on_index?
    return true unless params.dig("range", "lc_classification", "begin").blank?
    return true unless params.dig("range", "lc_classification", "end").blank?
    return true unless params.dig("f", "lc_outer_facet").blank?
    return true unless params.dig("f", "lc_inner_facet").blank?
    return true if params.dig("sort").present? && params["sort"].include?("lc_call_number_sort")
    false
  end
end
