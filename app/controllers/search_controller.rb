# frozen_string_literal: true

class SearchController < CatalogController
  include CatalogConfigReinit

  blacklight_config.configure do |config|
    config.add_search_field "all_fields", label: "All Fields"
    config.response_model = Search::Solr::Response

    config.add_index_field "format", label: "Resource Type", raw: true, helper_method: :index_translate_resource_type_code, no_label: true
    config.add_facet_field "format", label: "Resource Type", url_method: :path_for_books_and_media_facet, helper_method: :translate_resource_type_code, show: true, limit: -1
  end

  def index
    @per_page = 3
    if params[:q]
      engines = %i(books_and_media articles journals databases cdm)
      searcher = BentoSearch::ConcurrentSearcher.new(*engines)
      searcher.search(params[:q], per_page: @per_page, semantic_search_field: params[:field])
      @results = process_results(searcher.results)
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
    def process_results(results)
      # We only care about cdm results count not bento box.
      cdm_total_items = results["cdm"]&.total_items

      unless results["books_and_media"].blank?
        items = results["books_and_media"][0...-1]
        items.engine_id = results["books_and_media"].engine_id
        items.total_items = results["books_and_media"].total_items
        items.display_configuration = results["books_and_media"].display_configuration

        # Grabbing and setting @response in order to render facets.
        # Merges cdm totals into the @response.
        @response = results["books_and_media"].last.custom_data
        @response.merge_facet(name: "format", value: "digital_collections", hits: cdm_total_items)

        results.merge(
          "books_and_media" => items,
          ).except("cdm")
      else
        results.except("cdm")
      end
    end
end
