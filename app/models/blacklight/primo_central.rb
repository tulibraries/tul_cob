# frozen_string_literal: true

module Blacklight
  module PrimoCentral
    autoload :Document, "blacklight/primo_central/document"
    autoload :FacetPaginator, "blacklight/primo_central/facet_paginator"
    autoload :Repository, "blacklight/primo_central/repository"
    autoload :Request, "blacklight/primo_central/request"
    autoload :Response, "blacklight/primo_central/response"
    autoload :SearchBuilderBehavior, "blacklight/primo_central/search_builder_behavior"
    autoload :SolrAdaptor, "blacklight/primo_central/solr_adaptor"
  end
end
