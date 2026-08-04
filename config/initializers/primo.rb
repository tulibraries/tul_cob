# frozen_string_literal: true

require "logger"

Primo::Configuration.prepend(
  Module.new do
    def initialize(*)
      super
      @logger = Rails.logger || Logger.new($stdout)
    end
  end
)

Primo.configure do |config|
  config.apikey  = Rails.configuration.apis.dig(:primo, :apikey)
  config.context = :PC
  config.vid     = "01TULI_INST:TULI"
  config.scope   = "CentralIndex"
  config.enable_loggable = true
  config.enable_log_requests = true
  config.timeout = 3
  config.enable_retries = true
  config.retries = 3
end
