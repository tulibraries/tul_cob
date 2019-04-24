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
    formats.join("<br />")
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
    field = blacklight_config.show_fields["electronic_resource_display"]
    online_resources = [doc_presenter.field_value(field)]
      .select { |r| !r.empty? }.compact

    if !online_resources.empty?
      render "online_availability", online_resources: online_resources
    end
  end

  def render_online_availability_button(doc)
    links = check_for_full_http_link(document: doc, field: "electronic_resource_display")

    if !links.empty?
      render "online_availability_button", document: doc, links: links
    end
  end

  def render_bound_with_ids(document)
    if index_fields["bound_with_ids"] && document.alma_availability_mms_ids.present?
      content_tag :span, nil, class: "row document-metadata blacklight-availability availability-ajax-load", "data-availability-ids": document.alma_availability_mms_ids.join(",")
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

  def render_availability(doc)
    if index_fields(doc).fetch("availability", nil)
      render "index_availability_section", document: doc
    end
  end

  def render_purchase_order_availability(presenter)
    doc = presenter.document
    return unless doc.purchase_order?


    field = presenter.send(:fields)["purchase_order_availability"]

    if field.with_panel
      rows = [ t("purchase_order_allowed") ]
      render partial: "availability_panel", locals: { label: field.label, rows: rows }

    elsif current_user && !current_user.can_purchase_order?
      content_tag :div, t("purchase_order_allowed"), class: "availability border border-tan-border"
    else
      render_purchase_order_button(document: doc, config: field)
    end
  end

  def render_purchase_order_button(args)
    return unless args[:document].purchase_order?

    doc = args[:document]
    with_po_link = args.dig(:config, :with_po_link)

    if !current_user
      link = with_po_link ? render_purchase_order_show_link(args) : ""
      render partial: "purchase_order_anonymous_button", locals: { link: link, document: doc }
    elsif current_user.can_purchase_order?
      label = content_tag :span, "Request Rapid Access", class: "avail-label"
      path = purchase_order_path(id: doc.id)
      link = link_to label, path, class: "btn btn-sm btn-danger", title: "Open a modal form to request a purchase for this item.", target: "_blank", id: "purchase_order_button-#{doc.id}", data: { "blacklight-modal": "trigger" }
      content_tag :div, link, class: "requests-container"
    end
  end

  def render_purchase_order_show_link(args = { document: @document })
    return unless args[:document].purchase_order?

    if !current_user
      id = args[:document].id
      link_to("Log in to access request form", doc_redirect_url(id), data: { "blacklight-modal": "trigger" })
    elsif current_user.can_purchase_order?
      render_purchase_order_button(args)
    end
  end

  def render_email_form_field
    if !current_user&.email
      render partial: "email_form_field"
    end
  end

  def library_link
    Rails.configuration.library_link
  end

  def grouped_citations(documents)
    Citation.grouped_citations(documents.map(&:citations))
  end

  def render_marc_view
    if @document.respond_to?(:to_marc)
      render "marc_view", document: @response.documents.first
    else
      t("blacklight.search.librarian_view.empty")
    end
  end

  def back_to_catalog_path
    search_catalog_path(search_params)
  end

  def back_to_journals_path
    search_journals_path(search_params)
  end

  def back_to_articles_path
    search_path(search_params)
  end

  def back_to_databases_path
    search_databases_path(search_params)
  end

  def get_search_params(field, query)
    case field
    when "title_uniform_display", "title_addl_display"
      { search_field: "title", q: query }
    when "relation"
      { search_field: "title", q: query["relatedTitle"] }
    else
      { search_field: field, q: query }
    end
  end

  def fielded_search(query, field)
    params = get_search_params(field, query)
    link_url = search_action_path(params)
    title = params[:title] || params[:q]
    link_to(title, link_url)
  end

  def list_with_links(args)
    args[:document][args[:field]].map { |field| content_tag(:li,  fielded_search(field, args[:field]), class: "list_items") }.join("").html_safe
  end

  def creator_index_separator(args)
    creator = args[:document][args[:field]]
    creator.map do |name|
      plain_text_subfields = name.gsub("|", " ")
      creator = plain_text_subfields
    end
    creator
  end

  def subject_links(args)
    args[:document][args[:field]].map do |subject|
      link_to(subject.sub("— — ", "— "), "#{base_path}?f[subject_facet][]=#{CGI.escape subject}")
    end
  end

  def genre_links(args)
    args[:document][args[:field]].map do |genre|
      link_to(genre, "#{search_catalog_path}?f[genre_full_facet][]=#{CGI.escape genre}")
    end
  end

  def has_one_electronic_resource?(document)
    document.fetch("electronic_resource_display", []).length == 1
  end

  def has_many_electronic_resources?(document)
    electronic_resources = document.fetch("electronic_resource_display", [])
    electronic_resources.length > 1 ||
      has_one_electronic_resource?(document) &&
      render_electronic_notes(electronic_resources.first).present?
  end

  def check_for_full_http_link(args)
    [args[:document][args[:field]]].flatten.compact.map { |field|
      if field["url"].present?
        electronic_access_links(field)
      else
        electronic_resource_link_builder(field)
      end
    }.join("").html_safe
  end

  def electronic_access_links(field)
    text = field.fetch("title", "Link to Resource").sub(/ *[ ,.\/;:] *\Z/, "")
    url = field["url"]
    content_tag(:div, link_to(text, url, title: "Target opens in new window", target: "_blank"), class: "electronic_links online-list-items online-card")
  end

  def electronic_resource_link_builder(field)
    return if field.empty?
    return if field["availability"] == "Not Available"

    title = field.fetch("title", "Find it online")
    electronic_notes = render_electronic_notes(field)

    item_html = [render_alma_eresource_link(field["portfolio_id"], title), field["subtitle"]]
      .select(&:present?).join(" - ")
    item_html = [item_html, electronic_notes]
      .select(&:present?).join(" ").html_safe

    content_tag(:div, item_html , class: " electronic_links online-list-items online-card")
  end

  def render_electronic_notes(field)
    collection_id = field["collection_id"]
    service_id = field["service_id"]

    collection_notes = Rails.configuration.electronic_collection_notes[collection_id] || {}
    service_notes = Rails.configuration.electronic_service_notes[service_id] || {}

    if collection_notes.present? || service_notes.present?
      render partial: "electronic_notes", locals: { collection_notes: collection_notes, service_notes: service_notes }
    end
  end

  def render_alma_eresource_link(portfolio_pid, db_name)
    link_to(db_name, alma_electronic_resource_direct_link(portfolio_pid), title: "Target opens in new window", target: "_blank")
  end

  def alma_electronic_resource_direct_link(portfolio_pid)
    query = {
        "u.ignore_date_coverage": "true",
        "Force_direct": true,
        portfolio_pid: portfolio_pid
    }
    alma_build_openurl(query)
  end

  def alma_build_openurl(query)
    query_defaults = {
      rfr_id: "info:sid/primo.exlibrisgroup.com",
    }

    URI::HTTPS.build(
      host: alma_domain,
      path: "/view/uresolver/#{alma_institution_code}/openurl",
      query: query_defaults.merge(query).to_query).to_s
  end

  def single_link_builder(field)
    if field["url"].present?
      field["url"]
    else
      alma_electronic_resource_direct_link(field["portfolio_id"])
    end
  end

  def doc_id(id)
    "doc-#{id}"
  end

  def doc_redirect_url(id)
    new_user_session_with_redirect_path("#{request.url}##{doc_id(id)}")
  end

  def suggestions
    (@response.dig("spellcheck", "collations") || [])
      .each_slice(2)
      .map { |_, phrase| link_to_query(phrase) }
  end
end
