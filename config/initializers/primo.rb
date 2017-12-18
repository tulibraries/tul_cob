Primo.configure do |config|
  config.apikey = Rails.configuration.bento[:primo][:apikey]
  config.context = :PC
end
