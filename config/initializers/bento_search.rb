

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

BentoSearch.register_engine("more") do |conf|
  conf.engine = "BentoSearch::MoreEngine"
  conf.for_display do |display|
    display.decorator = "TulDecorator"
    display.linked_engines = ["resource_types"]
  end
end

BentoSearch.register_engine("resource_types") do |conf|
  conf.engine = "BentoSearch::MoreEngine"
  conf.for_display do |display|
    display.decorator = "TulDecorator"
    display.item_partial = "bento_search/more"
  end
end

BentoSearch.register_engine("articles") do |conf|
  conf.engine = "BentoSearch::PrimoEngine"
  conf.for_display do |display|
    display.decorator = "TulDecorator"
  end
end
