# frozen_string_literal: true

Primo.configure do |config|
  config.apikey  = Rails.configuration.bento[:primo][:apikey]
  config.context = :PC
  config.vid     = "TULI"
  config.scope   = "pci_scope"
end
