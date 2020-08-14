# frozen_string_literal: true

module FacetParamsDedupe
  extend ActiveSupport::Concern

  included do
    # Converts facet params like ?f[foo]=bar&f[foo]=bar to ?f[foo]=bar
    before_action do
      if params["f"]
        facet_params = params.extract!("f")
        params.merge!(f: facet_params["f"].transform_values { |v| v.is_a?(Array) ? v.uniq : v })
      end
    end
  end
end
