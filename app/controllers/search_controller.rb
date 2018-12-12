# frozen_string_literal: true

class SearchController < CatalogController
  include Blacklight::RequestBuilders
  include CatalogConfigReinit

  blacklight_config.configure do |config|
    config.add_index_field "format", label: "Resource Type", raw: true, helper_method: :index_translate_resource_type_code, no_label: true
    config.add_facet_field "format", label: "Resource Type", url_method: :path_for_more_facet
  end

  def index
    @per_page = 3
    if params[:q]
      engines = %i( books articles journals databases more )
      searcher = BentoSearch::ConcurrentSearcher.new(*engines)
      searcher.search(params[:q], per_page: @per_page, semantic_search_field: params[:field])
      @results = split_more(searcher.results)
      @response = @results["resource_types"]&.first&.custom_data
    end
  end

  # Splits results for the more engine into two bento_boxes.
  def split_more(results)
    unless results["more"].nil? || results["more"].empty?
      items = results["more"][0...-1]
      items.engine_id = results["more"].engine_id
      items.total_items = results["more"].total_items
      items.display_configuration = results["more"].display_configuration

      resource_types = results["more"].last
      resource_types.engine_id = "resource_types"
      resource_types = ::BentoSearch::Results.new([resource_types])
      resource_types.engine_id = "resource_types"
      resource_types.total_items = results["more"].total_items
      resource_types.display_configuration = BentoSearch.get_engine("resource_types").configuration[:for_display]

      results.merge(
        "more" => items,
        "resource_types" => resource_types,
        )
    else
      results
    end
  end
end
