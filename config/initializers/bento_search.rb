

BentoSearch.register_engine("blacklight") do |conf|
  conf.engine = "BentoSearch::BlacklightEngine"
end

BentoSearch.register_engine("primo") do |conf|
  conf.engine   = "BentoSearch::PrimoEngine"
  conf.base_url = Rails.configuration.bento[:primo][:base_url]
  conf.apikey   = Rails.configuration.bento[:primo][:apikey]
  conf.primo_base_web_url = Rails.configuration.bento[:primo][:primo_base_web_url]

end
