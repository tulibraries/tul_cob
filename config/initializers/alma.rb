# frozen_string_literal: true

Alma.configure do |config|
  alma_config = Rails.configuration.apis.dig(:alma) || {}

  # You have to set te apikey
  config.apikey = alma_config[:apikey]
  config.enable_loggable = true
  config.enable_log_requests = true
  config.timeout = alma_config[:timeout] || 30
end
