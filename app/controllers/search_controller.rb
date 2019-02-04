# frozen_string_literal: true

class SearchController < CatalogController
  include Blacklight::RequestBuilders
  include CatalogConfigReinit

  blacklight_config.configure do |config|
    config.search_fields = CatalogController.blacklight_config.search_fields
    config.response_model = Search::Solr::Response

    config.add_index_field "format", label: "Resource Type", raw: true, helper_method: :index_translate_resource_type_code, no_label: true
    config.add_facet_field "format", label: "Resource Type", url_method: :path_for_more_facet, helper_method: :translate_resource_type_code, show: true
  end

  def index
    @per_page = 3
    if params[:q]
      engines = %i( books articles journals databases more cdm)
      searcher = BentoSearch::ConcurrentSearcher.new(*engines)
      searcher.search(params[:q], per_page: @per_page, semantic_search_field: params[:field])
      @results = split_and_merge(searcher.results)
      @response = @results["resource_types"]&.first&.custom_data
    end

    respond_to do |format|
      format.html { store_preferred_view }
      format.json do
        @response ||= Blacklight::PrimoCentral::Response.new({})
        @results ||= []
        @presenter = Blacklight::JsonPresenter.new(@response,
                                                   @results,
                                                   [],
                                                   blacklight_config)
      end
    end
  end

  private
    # Splits results for the more engine into two bento_boxes.
    # Merges cdm totals with more results.
    def split_and_merge(results)
      # We only care about cdm results count not bento box.
      cdm_total_items = results["cdm"]&.total_items

      unless false #results["more"].blank? || cdm_total_items.nil?
        items = results["more"][0...-1]
        items.engine_id = results["more"].engine_id
        items.total_items = results["more"].total_items
        items.display_configuration = results["more"].display_configuration

        resource_types = results["more"].last
        resource_types.custom_data.merge_facet(name: "format", value: "cdm", hits: cdm_total_items)

        resource_types = ::BentoSearch::Results.new([resource_types])
        resource_types.engine_id = "resource_types"
        resource_types.engine_id = "resource_types"
        resource_types.total_items = 2 #results["more"].total_items
        resource_types.display_configuration = BentoSearch.get_engine("resource_types").configuration[:for_display]

        results.merge(
          "more" => items,
          "resource_types" => resource_types,
          ).except("cdm")
      else
        results.except("cdm")
      end
    end
end
