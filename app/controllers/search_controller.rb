# frozen_string_literal: true

class SearchController < CatalogController
  include CatalogConfigReinit

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
      engines = %i(books_and_media articles databases journals library_website lib_guides)
      searcher = BentoSearch::ConcurrentSearcher.new(*engines)
      searcher.search(params[:q], per_page: @per_page, semantic_search_field: params[:field])

      @results = process_results(searcher.results)
      @lib_guides_query_term = helpers.derived_lib_guides_search_term(@response)
      @cdm_records = cdm_records(params[:q])
    end

    respond_to do |format|
      format.html { store_preferred_view }
      format.json do

        @results["lib_guides_query_term"] = @lib_guides_query_term unless @results.nil?

        render plain: @results.to_json, status: 200, content_type: "application/json"
      end
    end
  end

  private
    def process_results(results)
      results.each_value do |result|
        Honeybadger.notify(result.error[:exception]) if result.failed?
      end
      # We only care about cdm results count not bento box.
      cdm_total_items = view_context.number_with_delimiter(results["cdm"]&.total_items)
      unless results["books_and_media"].blank?
        items = BentoSearch::Results.new(results["books_and_media"][0...-1])
        items.engine_id = results["books_and_media"].engine_id

        items.total_items = results["books_and_media"].total_items
        items.display_configuration = results["books_and_media"].display_configuration

        # Grabbing and setting @response in order to render facets.
        # Merges cdm records into the @response.
        @response = results["books_and_media"].last.custom_data
        @response.merge_facet(name: "format", value: "digital_collections", hits: cdm_total_items)

        results.merge(
          "books_and_media" => items
          ).except("cdm")
      else
        results.except("cdm")
      end
    end

    def cdm_records(query)
      # binding.pry
      query.gsub("/", " ")
      query = ERB::Util.url_encode(query)
      fields = "title!date"
      format = "json"
      cdm_url = "https://digital.library.temple.edu/digital/bl/dmwebservices/index.php?q=dmQuery/all/CISOSEARCHALL^#{query}^all^and/#{fields}/sortby/3/#{format}"
      results = []
      response = []

      begin
        response = JSON.load(URI.open(cdm_url))
        total_items = response.dig("pager", "total") || 0
        response["records"].each do |i|
          item = OpenStruct.new
          item.title = i.fetch("title")
          item.date = i.fetch("date")
          item.collection = i.fetch("collection")
          item.link = "https://digital.library.temple.edu/digital/collection#{i["collection"]}/id/#{i["pointer"]}"
          item.thumbnail = "https://digital.library.temple.edu/utils/ajaxhelper/?CISOROOT=#{i["collection"]}&CISOPTR=#{i["pointer"]}&action=2&DMSCALE=10&DMHEIGHT=340"
          results << item
        end 
      rescue StandardError => e
        total_items = 0
        Honeybadger.notify("Ran into error while try to process CDM: #{e.message}")
      end
      results
    end
end
