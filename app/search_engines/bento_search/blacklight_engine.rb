class BentoSearch::BlacklightEngine
  include BentoSearch::SearchEngine
  include Blacklight::SearchHelper

  def blacklight_config
    CatalogController.blacklight_config
  end

  def search_implementation(args)
    results = BentoSearch::Results.new
    bl_search = search_results({q: args[:query]})
    bl_search[0]["response"]["docs"].each do |item|
      result = BentoSearch::ResultItem.new({
        title: item.fetch("title_display", []).first,
        authors: item.fetch("creator_display", []).map { |author| BentoSearch::Author.new({display: author})},
        link: "http://localhost:3000/catalog/#{item['id']}"
        })
      results << result
    end
    results
  end

end
