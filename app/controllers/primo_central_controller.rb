# frozen_string_literal: true

class PrimoCentralController < CatalogController
  include Blacklight::Catalog
  include CatalogConfigReinit
  include Blacklight::Document::Export

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

    # Search fields
    config.add_search_field :any, label: "All Fields"
    config.add_search_field :title
    config.add_search_field :creator, label: "Author/Creator"
    config.add_search_field :sub, label: "Subject"
    config.add_search_field(:description, label: "Description") do |field|
      field.include_in_simple_select = false
    end
    config.add_search_field :isbn, label: "ISBN"
    config.add_search_field :issn, label: "ISSN"

    # Index fields
    config.add_index_field :isPartOf, label: "Is Part Of"
    config.add_index_field :creator, label: "Author/Creator", multi: true
    config.add_index_field :type, label: "Resource Type", raw: true, helper_method: :index_translate_resource_type_code
    config.add_index_field :date, label: "Year"
    config.add_index_field :availability

    # Facet fields
    config.add_facet_field :tlevel, label: "Article Search Settings", collapse: false, home: true, helper_method: :translate_availability_code
    config.add_facet_field :rtype, label: "Resource Type", limit: true, show: true, home: true, helper_method: :translate_resource_type_code
    config.add_facet_field :creationdate, label: "Date", range: true
    config.add_facet_field :creator, label: "Author/Creator"
    config.add_facet_field :topic, label: "Topic"
    config.add_facet_field :lang, label: "Language", limit: true, show: true, helper_method: :translate_language_code

    # Show fields
    # See for refwork tag definitions:
    # https://www.refworks.com/refworks/help/refworks_tagged_format.htm
    config.add_show_field :creator, label: "Author/Creator", helper_method: :browse_creator, multi: true, refwork_tag: :A1
    config.add_show_field :contributor, label: "Contributor", helper_method: :browse_creator, multi: true, refwork_tag: :A2
    config.add_show_field :type, label: "Resource Type", helper_method: :doc_translate_resource_type_code
    config.add_show_field :publisher, label: "Published", refwork_tag: :PB
    config.add_show_field :date, label: "Date", refwork_tag: :Y1
    config.add_show_field :isPartOf, label: "Is Part of", refwork_tag: :JF
    config.add_show_field :relation, label: "Related Title", helper_method: "list_with_links"
    config.add_show_field :description, label: "Note", helper_method: :tags_strip, refwork_tag: :AB
    config.add_show_field :subject, helper_method: :list_with_links, multi: true, refwork_tag: :KW
    config.add_show_field :isbn, label: "ISBN", refwork_tag: :SN
    config.add_show_field :issn, label: "ISSN", refwork_tag: :SN
    config.add_show_field :lccn, label: "LCCN"
    config.add_show_field :doi, label: "DOI"
    config.add_show_field :languageId, label: "Language", multi: true, helper_method: :doc_translate_language_code, refwork_tag: :LA

    # Sort fields
    config.add_sort_field :rank, label: "relevance"
    config.add_sort_field :date, label: "date (new to old)"
    config.add_sort_field :author, label: "author/creator (A to Z)"
    config.add_sort_field :title, label: "title (A to Z)"
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
