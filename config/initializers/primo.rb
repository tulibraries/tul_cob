# frozen_string_literal: true

Primo.configure do |config|
  config.apikey = Rails.configuration.bento[:primo][:apikey]
  config.context = :L
  config.vid = "TULI"
  config.scope = "default_scope"
end
