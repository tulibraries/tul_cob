# frozen_string_literal: true

class SearchController < CatalogController
  include CatalogConfigReinit
  before_action :configure_bento_item_partials, only: :index

  blacklight_config.configure do |config|
    config.add_search_field "all_fields", label: "All Fields"
    config.response_model = Search::Solr::Response

    config.add_index_field "format", label: "Resource Type", raw: true, helper_method: :index_translate_resource_type_code, no_label: true
    config.add_facet_field "format", label: "Resource Type", url_method: :path_for_books_and_media_facet, helper_method: :translate_resource_type_code, show: true, limit: -1
    config.add_facet_field "subject_topic_facet", limit: true
  end

  def index
    @per_page = 3
    if params[:q]
      engines = %i(books_and_media articles archival_collections databases journals library_website lib_guides cdm)
      searcher = BentoSearch::ConcurrentSearcher.new(*engines)
      searcher.search(params[:q], per_page: @per_page, semantic_search_field: params[:field])
      @results = process_results(searcher.results)
      @results = apply_bento_item_partials(@results)
      @lib_guides_results = extract_engine_result(@results, "lib_guides")
      @lib_guides_query_term = helpers.derived_lib_guides_search_term(@response)
    end

    respond_to do |format|
      format.html do
        store_preferred_view
        template = Flipflop.style_updates? ? "search/index_new" : "search/index"
        render template
      end
      format.json do

        @results["lib_guides_query_term"] = @lib_guides_query_term unless @results.nil?

        render plain: @results.to_json, status: 200, content_type: "application/json"
      end
    end
  end

  private
    def configure_bento_item_partials
      item_partial = Flipflop.style_updates? ? "bento_search/std_item_new" : "bento_search/std_item"
      bento_engines = %w[blacklight journals databases library_website books_and_media articles cdm lib_guides]

      bento_engines.each do |engine_id|
        configuration = BentoSearch.get_engine(engine_id).configuration
        display_config = configuration.for_display
        if display_config.respond_to?(:item_partial=)
          display_config.item_partial = item_partial
        end

        # retain hash-style access used elsewhere in the app
        configuration[:for_display][:item_partial] = item_partial
      end
    end

    def apply_bento_item_partials(results)
      return results unless results.is_a?(Hash)

      item_partial = Flipflop.style_updates? ? "bento_search/std_item_new" : "bento_search/std_item"

      results.each_value do |result|
        next unless result.respond_to?(:display_configuration)

        config = result.display_configuration
        next unless config

        config.item_partial = item_partial if config.respond_to?(:item_partial=)
        config[:item_partial] = item_partial if config.respond_to?(:[])
      end

      results
    end

    def extract_engine_result(results, engine_id)
      return nil unless results.respond_to?(:[])

      results[engine_id] || results[engine_id.to_sym]
    end

    def process_results(results)
      results.each_value do |result|
        Honeybadger.notify(result.error[:exception]) if result.failed?
      end

      unless results["books_and_media"].blank?
        items = BentoSearch::Results.new(results["books_and_media"][0...-1])
        items.engine_id = results["books_and_media"].engine_id
        items.total_items = results["books_and_media"].total_items
        items.display_configuration = results["books_and_media"].display_configuration

        # Grabbing and setting @response in order to render facets.
        @response = results["books_and_media"].last.custom_data

        results.merge(
          "books_and_media" => items
          )
      else
        results
      end
    end

end
