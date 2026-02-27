# frozen_string_literal: true

Alma.configure do |config|
  # You have to set te apikey
  config.apikey = IntegrationConfig.alma(:apikey)
  config.enable_loggable = true
  config.enable_log_requests = true
  config.timeout = IntegrationConfig.alma(:timeout) || 30
end
ENV["ALMA_API_KEY"] ||= IntegrationConfig.alma(:apikey)
ENV["ALMA_DELIVERY_DOMAIN"] ||= IntegrationConfig.alma(:delivery_domain)
ENV["ALMA_INSTITUTION_CODE"] ||= IntegrationConfig.alma(:institution_code)
ENV["ALMA_AUTH_SECRET"] ||= IntegrationConfig.alma_auth_secret
