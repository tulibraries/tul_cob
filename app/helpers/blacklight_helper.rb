# frozen_string_literal: true

module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior

  def only_home_facets(solr_parameters, user_paramters)
    solr_parameters["facet.field"], solr_parameters["facet.pivot"] = home_facets, [] unless has_search_parameters?
  end
end
