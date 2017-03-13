BentoSearch.register_engine("summon") do |conf|
  conf.engine = "BentoSearch::SummonEngine"
  conf.secret_key = Rails.configuration.bento[:summon][:secret_key]
  conf.access_id = Rails.configuration.bento[:summon][:access_id]
  conf.nice_name = Rails.configuration.bento[:summon][:nice_name]
  # any other configuration
end

BentoSearch.register_engine("gbs") do |conf|
  conf.engine = "BentoSearch::GoogleBooksEngine"
  conf.api_key =  Rails.configuration.bento[:gbs][:api_key]
  conf.nice_name = Rails.configuration.bento[:gbs][:nice_name]
end