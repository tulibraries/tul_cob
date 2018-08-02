# frozen_string_literal: true

module SearchHelper
  ##
  # Links More bento block facet back to catalog.
  # @param [Blacklight::Solr::Response::Facets::FacetField] facet_field
  # @param [String] item
  # @return [String]
  def path_for_more_facet(facet_field, item)
    search_catalog_url(search_state.add_facet_params_and_redirect(facet_field, item))
  end

  def renderable_results
    @results.select { |engine_id, result| render_search? result }
  end

  def render_search?(result)
    engine_id = result.engine_id
    ! ((engine_id == "more" ||
        engine_id == "resource_types" ||
        engine_id == "articles") &&
       total_items(result) == 0)
  end

  def bento_titleize(id)
    engine = BentoSearch.get_engine(id)
    link_to id.titleize , engine.url(self)
  end
end
