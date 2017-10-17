# frozen_string_literal: true

Alma.configure do |config|
  # You have to set te apikey
  config.apikey = Rails.configuration.alma[:apikey]

end
ENV["ALMA_API_KEY"] ||= Rails.configuration.alma[:apikey]
ENV["ALMA_DELIVERY_DOMAIN"] ||= Rails.configuration.alma[:delivery_domain]
ENV["ALMA_INSTITUTION_CODE"] ||= Rails.configuration.alma[:institution_code]
