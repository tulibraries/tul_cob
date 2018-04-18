

# frozen_string_literal: true

BentoSearch.register_engine("blacklight") do |conf|
  conf.engine = "BentoSearch::BlacklightEngine"
  conf.for_display do |display|
    display.decorator = "TulDecorator"
  end
end

BentoSearch.register_engine("journals") do |conf|
  conf.engine = "BentoSearch::JournalsEngine"
  conf.for_display do |display|
    display.decorator = "TulDecorator"
  end
end

BentoSearch.register_engine("books") do |conf|
  conf.engine = "BentoSearch::BooksEngine"
  conf.for_display do |display|
    display.decorator = "TulDecorator"
  end
end

BentoSearch.register_engine("primo") do |conf|
  conf.engine = "BentoSearch::PrimoEngine"
  conf.api_base_url = Rails.configuration.bento[:primo][:api_base_url]
  conf.apikey = Rails.configuration.bento[:primo][:apikey]
  conf.scope = Rails.configuration.bento[:primo][:scope]
  conf.vid = Rails.configuration.bento[:primo][:vid]
  conf.web_ui_base_url = Rails.configuration.bento[:primo][:web_ui_base_url]
  conf.for_display do |display|
    display.decorator = "TulDecorator"
  end
end
