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
    value = document.fetch(:isbn_display, []).first
    # Get the first ISBN and strip non-numerics
    "data-isbn=#{value.gsub(/\D/, '')}" if value
  end

  def lccn_data_attribute(document)
    value = document.fetch(:lccn_display, []).first
    # Get the first ISSN and strip non-numerics
    "data-lccn=#{value.first.gsub(/\D/, '')}" if value
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
end
