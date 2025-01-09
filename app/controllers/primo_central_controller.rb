# frozen_string_literal: true

class PrimoCentralController < CatalogController
  include Blacklight::Catalog
  include CatalogConfigReinit
  include Blacklight::Document::Export

  before_action :recaptcha, only: [ :index ]

  helper_method :browse_creator
  helper_method :tags_strip
  helper_method :solr_range_queries_to_a

  def recaptcha
    # skip if recaptcha site key not set (using as feature flag)
    return if ENV["RECAPTCHA_SITE_KEY"].blank?

    @recaptcha_action = "articles_search"

    # skip if referred from app.
    return if request.referer.present? && URI.parse(request.referer).host == request.host

    # skip if nothing to query.
    return if params["q"].blank?

    if !verify_recaptcha(action: @recaptcha_action)
      raise Recaptcha::VerifyError.new("recaptcha verification failed for #{@recaptcha_action}")
    end
  end


  def advanced_override_path
  end

  rescue_from ArticleNotFound, with: :invalid_document_id_error
  rescue_from Net::ReadTimeout, with: :net_read_timeout_rescue

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

    config.add_show_tools_partial(:bookmark, partial: "bookmark_control", if: false)
    config.add_nav_action(:bookmark, partial: "blacklight/nav/bookmark", if: true)
    config.add_results_document_tool(:bookmark, partial: "bookmark_control", if: false)

    # Search fields
    config.add_search_field :any, label: "All Fields", catalog_map: :all_fields
    config.add_search_field :title
    config.add_search_field :creator, label: "Author/Creator", catalog_map: :creator_t
    config.add_search_field :sub, label: "Subject", catalog_map: :subject
    config.add_search_field(:description, label: "Description", catalog: :note_t) do |field|
      field.include_in_simple_select = false
    end
    config.add_search_field :isbn, label: "ISBN", catalog_map: :isbn_t
    config.add_search_field :issn, label: "ISSN", catalog_map: :issn_t

    # Index fields
    config.add_index_field :description, type: :summary
    config.add_index_field :type, label: "Resource Type", raw: true, helper_method: :index_translate_resource_type_code, type: :format
    config.add_index_field :date, label: "Year", type: :date
    config.add_index_field :isPartOf, label: "Is Part Of"
    config.add_index_field :creator, label: "Author/Creator", helper_method: :creator_links, multi: true, separator: ", "
    config.add_index_field :availability
    config.add_index_field :status
    config.add_index_field :error

    # Facet fields
    config.add_facet_field :tlevel, label: "Article Search Settings", collapse: false, home: true, helper_method: :translate_availability_code, component: true
    config.add_facet_field :rtype, label: "Resource Type", limit: true, show: true, home: true, helper_method: :translate_resource_type_code, component: true
    config.add_facet_field :creationdate, label: "Date", range: true, component: RangeFacetFieldListComponent
    config.add_facet_field :creator, label: "Author/Creator", component: true
    config.add_facet_field :topic, label: "Topic", component: true
    config.add_facet_field :lang, label: "Language", limit: true, show: true, helper_method: :translate_language_code, component: true

    # Show fields
    config.add_show_field :creator, label: "Author/Creator", helper_method: :creator_links, multi: true, refwork_tag: :A1, type: :primary
    config.add_show_field :contributor, label: "Contributor", helper_method: :creator_links, multi: true, refwork_tag: :A2, type: :primary
    config.add_show_field :type, label: "Resource Type", helper_method: :doc_translate_resource_type_code, type: :primary
    config.add_show_field :isPartOf, label: "Is Part of", refwork_tag: :JF, type: :primary
    config.add_show_field :date, label: "Date", refwork_tag: :Y1, type: :primary
    config.add_show_field :publisher, label: "Published", refwork_tag: :PB
    config.add_show_field :relation, label: "Related Title", helper_method: "list_with_links"
    config.add_show_field :description, label: "Note", helper_method: :tags_strip, refwork_tag: :AB
    config.add_show_field :subject, helper_method: :list_with_links, multi: true, refwork_tag: :KW
    config.add_show_field :isbn, label: "ISBN", refwork_tag: :SN
    config.add_show_field :issn, label: "ISSN", refwork_tag: :SN
    config.add_show_field :lccn, label: "LCCN"
    config.add_show_field :doi, label: "DOI"
    config.add_show_field :language, label: "Language", multi: true, helper_method: :doc_translate_language_code, refwork_tag: :LA

    # Sort fields
    config.add_sort_field :rank, label: "relevance"
    config.add_sort_field :date_d, label: "date (new to old)"
    config.add_sort_field :author, label: "author/creator (A to Z)"
    config.add_sort_field :title, label: "title (A to Z)"
  end

  def tags_strip(args)
    args[:value].map { |v| helpers.strip_tags v }
  end

  # This method is required and used by blacklight_range_limit gem.
  def solr_range_queries_to_a(solr_field)
    @response[:stats][:stats_fields][solr_field][:data] || []
  end

  def net_read_timeout_rescue(exception)
    Honeybadger.notify(exception)

    flash[:error] = "Your search has timed out."
    flash[:error] += " You may have exceeded the maximum number of pages allowed for Article search results in Library Search." if params[:page].to_i >= 50

    redirect_to "/articles"
  end
end
