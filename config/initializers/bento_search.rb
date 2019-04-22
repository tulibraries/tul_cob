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
    display.no_results_partial = "bento_search/no_journal_results"
  end
end

BentoSearch.register_engine("databases") do |conf|
  conf.engine = "BentoSearch::DatabasesEngine"
  conf.for_display do |display|
    display.decorator = "TulDecorator"
    display.no_results_partial = "bento_search/no_database_results"
  end
end

BentoSearch.register_engine("books_and_media") do |conf|
  conf.engine = "BentoSearch::BooksAndMediaEngine"
  conf.for_display do |display|
    display.decorator = "TulDecorator"
    display.linked_engines = ["resource_types"]
    display.no_results_partial = "bento_search/no_book_results"
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
    display.no_results_partial = "bento_search/no_article_results"
  end
end

BentoSearch.register_engine("cdm") do |conf|
  conf.engine = "BentoSearch::CDMEngine"
  conf.for_display do |display|
    display.decorator = "TulDecorator"
    display.no_results_partial = "bento_search/no_article_results"
  end
end
