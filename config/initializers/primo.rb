# frozen_string_literal: true

Primo.configure do |config|
  config.apikey  = ENV["PRIMO_API_KEY"] || Rails.configuration.bento&.dig(:primo, :apikey)
  config.context = :PC
  config.vid     = "TULI"
  config.scope   = "pci_scope"
  config.enable_loggable = true
  config.timeout = Rails.configuration.bento&.dig(:primo, :timeout) || 10
  config.timeout = Rails.configuration.bento&.dig(:primo, :timeout) || 10
end
