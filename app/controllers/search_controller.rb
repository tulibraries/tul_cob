# frozen_string_literal: true

class SearchController < CatalogController
  include Blacklight::RequestBuilders
  include CatalogConfigReinit

  blacklight_config.configure do |config|
    config.add_index_field "format", label: "Resource Type", raw: true, helper_method: :separate_formats
    config.add_facet_field "format", label: "Resource Type", url_method: :path_for_more_facet
  end

  def index
    @per_page = 3
    if params[:q]
      engines = %i( books articles journals more )
      searcher = BentoSearch::ConcurrentSearcher.new(*engines)
      searcher.search(params[:q], per_page: @per_page, semantic_search_field: params[:field])
      @results = searcher.results
      @response = @results["more"]&.last&.custom_data
    end
  end

  def single_search
    begin
      @engine = BentoSearch.get_engine(params[:engine])
    rescue BentoSearch::NoSuchEngine => e
      render status: 404, text: e.message
      return
    end

    if params[:q]
      args = {}
      args[:query] = params[:q]
      args[:page] = params[:page]
      args[:semantic_search_field] = params[:field]
      args[:sort] = params[:sort]
      args[:per_page] = @per_page

      @results = @engine.search(params[:q], args)
    end

    respond_to do |format|
      format.html
      format.atom { render template: "bento_search/atom_results", locals: { atom_results: @results } }
    end
  end
end
