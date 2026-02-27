# frozen_string_literal: true

Primo.configure do |config|
  config.apikey  = IntegrationConfig.primo_api_key
  config.context = :PC
  config.vid     = "01TULI_INST:TULI"
  config.scope   = "CentralIndex"
  config.enable_loggable = true
  config.enable_log_requests = true
  config.timeout = 3
  config.enable_retries = true
  config.retries = 3
end
