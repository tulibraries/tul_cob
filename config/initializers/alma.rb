Alma.configure do |config|
  # You have to set te apikey
  config.apikey     = Rails.configuration.alma[:apikey]
end