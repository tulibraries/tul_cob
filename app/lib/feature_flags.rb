# frozen_string_literal: true

module FeatureFlags
  def self.campus_closed?(params = nil)
    # a passed campus_closed param overrides env var
    if !params.nil? && params.has_key?("campus_closed")
      return (params["campus_closed"] == "false") ? false : true
    end
    !!Rails.configuration.features.fetch(:campus_closed, false)
  end

  def self.with_libguides?(params = nil)
    if !params.nil? && params.has_key?("with_libguides")
      return (params["with_libguides"] == "false") ? false : true
    end
    !!Rails.configuration.features.fetch(:with_libguides, false)
  end

  def self.libwizard_tutorial?(params = nil)
    if !params.nil? && params.has_key?("libwizard_tutorial")
      return (params["libwizard_tutorial"] == "false") ? false : true
    end
    !!Rails.configuration.features.fetch(:libwizard_tutorial, false)
  end

  def self.recaptcha?(params = nil)
    if !params.nil? && params.has_key?("recaptcha")
      return (params["recaptcha"] == "false") ? false : true
    end
    !!Rails.configuration.features.fetch(:recaptcha, false)
  end
end
