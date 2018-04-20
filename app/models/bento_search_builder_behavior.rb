# frozen_string_literal: true

module BentoSearchBuilderBehavior
  extend ActiveSupport::Concern

  def remove_facets(solr_params)
    # Remove all field faceting for efficiency, we won't be using it.
    solr_params.delete("facet.field")
    solr_params.delete("facet.field".to_sym)
    solr_params["stats"] = false
    solr_params["facets"] = false
  end

  def format_facet_only(solr_params)
    # Facet on one field and return no result rows.
    solr_params["facet.field"] = "format"
    solr_params["facets"] = true
    solr_params["rows"] = 0;
  end
end
