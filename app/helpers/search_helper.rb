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

  def empty_resource_types?(result)
    engine_id = result.engine_id
    (engine_id == "more" || engine_id == "resource_types") && total_items(result) == 0
  end
end
