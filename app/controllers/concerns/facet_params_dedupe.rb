# frozen_string_literal: true

module FacetParamsDedupe
  extend ActiveSupport::Concern

  included do
    # Converts facet params like ?f[foo]=bar&f[foo]=bar to ?f[foo]=bar
    before_action do
      next unless params["f"]

      unless params["f"].respond_to?(:transform_values)
        render plain: "Invalid request", status: :bad_request, content_type: "text/plain"
        next
      end

      facet_params = params.extract!("f")
      params.merge!(f: facet_params["f"].transform_values { |v| v.is_a?(Array) ? v.uniq : v })
    end
  end
end
