# frozen_string_literal: true

class PrimoCentralController < CatalogController
  include Blacklight::Catalog

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


    # Index fields
    config.add_index_field "pub_date", label: "Year"
    config.add_index_field "subtitle", label: "Subtitle"

    # Show fields
    config.add_show_field "isPartOf", label: "Is Part of"
    config.add_show_field "relation", label: "Related Title", helper_method: "list_with_links"
    config.add_show_field "doi", label: "DOI"
  end

  # get a single document from the index
  # to add responses for formats other than html or json see _Blacklight::Document::Export_
  def show
    @document = repository.find params[:id]
    respond_to do |format|
      format.html { setup_next_and_previous_documents }
      format.json { render json: { response: { document: @document } } }
      additional_export_formats(@document, format)
    end
  end

  def render_sms_action?(_config, _options)
    # Render if the item can be found at a library
    false
  end
end
