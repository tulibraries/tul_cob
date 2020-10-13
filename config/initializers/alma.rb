# frozen_string_literal: true

ENV["ALMA_API_KEY"] ||= Rails.configuration.alma[:apikey]
ENV["ALMA_DELIVERY_DOMAIN"] ||= Rails.configuration.alma[:delivery_domain]
ENV["ALMA_INSTITUTION_CODE"] ||= Rails.configuration.alma[:institution_code]
ENV["ALMA_AUTH_SECRET"] ||= Rails.configuration.alma[:auth_secret]

Alma.configure do |config|
  # You have to set te apikey
  config.apikey = ENV["ALMA_API_KEY"]
  config.enable_loggable = true
  config.timeout = Rails.configuration.alma[:timeout] || 30
end
