# frozen_string_literal: true

class SearchController < CatalogController
  include Blacklight::RequestBuilders

  blacklight_config.configure do |config|
    # Reinitialize field configurations
    config.search_fields = ActiveSupport::OrderedHash.new
    config.show_fields = ActiveSupport::OrderedHash.new
    config.facet_fields = ActiveSupport::OrderedHash.new
    config.index_fields = ActiveSupport::OrderedHash.new
    config.sort_fields = ActiveSupport::OrderedHash.new
    config.add_facet_field "format", label: "Resource Type", collapse: false, limit: false
  end

  @@per_page = 10
  def index
    if params[:q]
      engines = %i( blacklight journals books primo  more )
      searcher = BentoSearch::ConcurrentSearcher.new(*engines)
      searcher.search(params[:q], per_page: @@per_page, semantic_search_field: params[:field])
      @results = searcher.results
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
      args[:per_page] = 10
      args[:sort] = params[:sort]
      args[:per_page] = params[:per_page]

      @results = @engine.search(params[:q], args)
    end

    respond_to do |format|
      format.html
      format.atom { render template: "bento_search/atom_results", locals: { atom_results: @results } }
    end
  end

  protected
    # Get controller to find templates in CatalogController too,
    # so we can reuse facet templates.
    def self.local_prefixes
      @local_prefixes ||= super.push("catalog")
    end
end
