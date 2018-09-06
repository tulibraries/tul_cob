# frozen_string_literal: true

class PrimoCentralController < CatalogController
  include Blacklight::Catalog
  include CatalogConfigReinit
  include Blacklight::Document::Export
  include PrimoFieldsConfig

  helper_method :browse_creator
  helper_method :tags_strip
  helper_method :solr_range_queries_to_a

  # We are not including the default configuration by default until we are sure all features work with Primo.
  add_show_tools_partial(:bookmark, partial: "bookmark_control")
  add_show_tools_partial(:refworks, partial: "tagged_refworks", modal: false)
  add_nav_action(:bookmark, partial: "blacklight/nav/bookmark")
  add_results_document_tool(:bookmark, partial: "bookmark_control")


  configure_blacklight do |config|
    # Class for sending and receiving requests from a search index
    config.repository_class = Blacklight::PrimoCentral::Repository

    # Class for converting Blacklight's url parameters to into request parameters for the search index
    config.search_builder_class = Blacklight::PrimoCentral::SearchBuilder

    # Model that describes a Document
    config.document_model = ::PrimoCentralDocument

    # Model that maps search index responses to the blacklight response model
    config.response_model = Blacklight::PrimoCentral::Response

    config.index.document_presenter_class = PrimoCentralPresenter

    # Pagination handler
    config.facet_paginator_class = Blacklight::PrimoCentral::FacetPaginator
  end

  def browse_creator(args)
    creator = args[:document][args[:field]] || []
    base_path = helpers.base_path
    creator.map do |name|
      query = view_context.send(:url_encode, (name))
      view_context.link_to(name, base_path + "?search_field=creator&q=#{query}")
    end
  end

  def tags_strip(args)
    args[:value].map { |v| helpers.strip_tags v }
  end

  # This method is required and used by blacklight_range_limit gem.
  def solr_range_queries_to_a(solr_field)
    @response[:stats][:stats_fields][solr_field][:data] || []
  end
end
