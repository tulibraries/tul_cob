# frozen_string_literal: true

module CatalogHelper
  include Blacklight::CatalogHelperBehavior
  include BlacklightAlma::CatalogOverride

  def thumbnail_classes(document)
    classes = %w[thumbnail col-sm-3 col-lg-2]
    document.fetch(:format, []).compact.each do |format|
      classes << "#{format.parameterize.downcase.underscore}_format"
    end
    classes.join " "
  end

  def isbn_data_attribute(document)
    values = document.fetch(:isbn_display, [])
    values = [values].flatten.map { |value|
      value.gsub(/\D/, "") if value
    }.compact.join(",")

    "data-isbn=#{values}" if !values.empty?
  end

  def lccn_data_attribute(document)
    values = document.fetch(:lccn_display, [])
    values = [values].flatten.map { |value|
      value.gsub(/\D/, "") if value
    }.compact.join(",")

    "data-lccn=#{values}" if !values.empty?
  end

  def default_cover_image(document)
    formats = document.fetch(:format, [])
    # In case we fetched the default value, or the format value was ""
    formats << "unknown" if formats.empty?
    format = formats.first.to_s.parameterize.underscore
    image = Rails.application.config.assets.default_cover_image
      .merge(
        "article" => "journal_periodical",
        "dissertation" => "script",
        "dissertation_thesis" => "script",
        "government_document" => "journal_periodical",
        "journal" => "journal_periodical",
        "legal_document" => "journal_periodical",
        "newspaper_article" => "journal_periodical",
        "other" => "unknown",
        "patent" => "journal_periodical",
        "reference_entry" => "journal_periodical",
        "research_dataset" => "dataset",
        "review" => "journal_periodical",
        "statistical_data_set" => "dataset",
        "technical_report" => "journal_periodical",
        "book_chapter" => "book",
        "text_resource" => "journal_periodical",
    ).fetch(format, "unknown")

    "svg/" + image + ".svg"
  end

  def separate_formats(response)
    document = response[:document]
    formats = %w[]
    document[:format].each do |format|
      format = h(format)
      css_class = format.to_s.parameterize.underscore
      formats << "<span class='#{css_class}'> #{format}</span>"
    end
    formats.join("<span class='format-concatenator'>and</span>")
  end

  # Used to toggle the search bar form path.
  # Hack for Advanced search page
  def search_url_picker
    current_page?("/advanced") ? search_catalog_url : search_action_url
  end

  # Overridden because we want to use our merged @response["docs"] with docs
  # from solr and primo together.
  def current_bookmarks(response = nil)
    response ||= @response
    @current_bookmarks ||=
      current_or_guest_user
      .bookmarks_for_documents(@response["docs"] ||
    response.documents).to_a
  end

  ##
  # Overridden so that we can controll the number of pages from the controller.
  #
  # Look up the current per page value, or the default if none if set
  #
  # @return [Integer]
  def current_per_page
    (@response["rows"] if @response["rows"] && @response["rows"] > 0) ||
      (@response.rows if @response && @response.rows > 0) ||
      params.fetch(:per_page, default_per_page).to_i
  end

  def render_online_availability(doc_presenter)
    online_resources = [doc_presenter.field_value("electronic_resource_display")]
      .select { |r| !r.empty? }.compact

    if !online_resources.empty?
      render "online_availability", online_resources: online_resources
    end
  end

  def render_online_availability_button(doc, count)
    links = check_for_full_http_link(document: doc, field: "electronic_resource_display")

    if !links.empty?
      render "online_availability_button", document: doc, document_counter: count, links: links
    end
  end

  ##
  # Overridden from module Blacklight::BlacklightHelperBehavior.
  #
  # Overridden in order to disable rel alternate links added to page headers.
  def render_link_rel_alternates(document = @document, options = {})
    ""
  end

  def advanced_catalog_search_path
    params = @search_state.to_h.select { |k, v| !["page"].include? k }
    blacklight_advanced_search_engine.advanced_search_path(params)
  end

  def render_availability(doc, count)
    if index_fields(doc).fetch("availability", nil)
      render "index_availability_section", document: doc, document_counter: count
    end
  end

  def library_link
    Rails.configuration.library_link
  end

  def grouped_citations(documents)
    Citation.grouped_citations(documents.map(&:citations))
  end
end
