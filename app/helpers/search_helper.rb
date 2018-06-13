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

  def bento_more_partials(item)
    partials = []

    if item.title
      partials.append("more_item")
    else
      partials.append("more_facets")
    end
  end
end
