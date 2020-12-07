# frozen_string_literal: true

module LCClassifications
  extend ActiveSupport::Concern

  def render_lc_call_number_on_index?
    params.dig("range", "lc_classification", "begin").present? ||
      params.dig("range", "lc_classification", "end").present? ||
      params.dig("f", "lc_outer_facet").present? ||
      params.dig("f", "lc_inner_facet").present? ||
      !!(params.dig("sort").&include?("lc_call_number_sort"))
  end
end
