# frozen_string_literal: true

module FeatureFlags
  def self.campus_closed?(params = nil)
    # a passed campus_closed param overrides env var
    if !params.nil? && params.has_key?("campus_closed")
      return (params["campus_closed"] == "false") ? false : true
    end
    !!Rails.configuration.features.fetch(:campus_closed, false)
  end
end
