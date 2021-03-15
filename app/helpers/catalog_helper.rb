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

  def oclc_data_attribute(document)
    values = document.fetch(:oclc_number_display, [])
    values = [values].flatten.map { |value|
      value.gsub(/\D/, "") if value
    }.compact.join(",")

    "data-oclc=#{values}" if !values.empty?
  end

  def lccn_data_attribute(document)
    values = document.fetch(:lccn_display, []).compact.join(",")

    "data-lccn=#{values}" if !values.empty?
  end

  def render_google_books_data_attribute(document)
    isbn_data_attribute(document) || lccn_data_attribute(document) || oclc_data_attribute(document)
  end

  def default_cover_image(document)
    formats = document.fetch(:format, [])
    # In case we fetched the default value, or the format value was ""
    formats << "unknown" if formats.empty?
    format = formats.first.to_s.parameterize.underscore
    image = Rails.application.config.assets.default_cover_image
      .merge(
        "archival_material_manuscript" => "archival_material",
        "article" => "journal_periodical",
        "book_chapter" => "book",
        "book_review" => "legal",
        "computer_file" => "computer_media",
        "dissertation" => "script",
        "dissertation_thesis" => "script",
        "government_document" => "legal",
        "image" => "visual_material",
        "journal" => "journal_periodical",
        "legal_document" => "legal",
        "market_research" => "dataset",
        "microform" => "legal",
        "newspaper" => "legal",
        "newspaper_article" => "legal",
        "other" => "unknown",
        "patent" => "legal",
        "reference_entry" => "legal",
        "report" => "legal",
        "research_dataset" => "dataset",
        "review" => "legal",
        "standard" => "legal",
        "statistical_data_set" => "dataset",
        "technical_report" => "legal",
        "text_resource" => "legal",
        "web_resource" => "website",
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
    formats.join("<br />").html_safe
  end

  # Used to toggle the search bar form path.
  # Hack for Advanced search page
  def search_url_picker
    current_page?("/advanced") ? search_catalog_url : search_action_url
  end

  def render_online_availability(doc_presenter)
    field = blacklight_config.show_fields["electronic_resource_display"]
    return if field.nil?

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

  def render_alma_availability(document)
    # We are checking index_fields["bound_with_ids"] because that is a field that is unique to catalog records
    # We do not want this to render if the item is from Primo, etc.
    if index_fields["bound_with_ids"] && document.alma_availability_mms_ids.present?
      content_tag :dl, nil, class: "row document-metadata blacklight-availability availability-ajax-load my-0 mr-5", "data-availability-ids": document.alma_availability_mms_ids.join(",")
    end
  end

  def render_lc_display_field(field_presenter)
    content_tag :dl, nil, class: "row document-metadata my-0 mr-5 blacklight-lc_call_number_display" do
      html = content_tag :dt, "LC Classification:", class: "py-2 index-label col-sm-12 col-md-4 col-lg-3 blacklight-lc_call_number_display"
      html += content_tag :dd, field_presenter.render, class: "py-2 col-sm-12 col-md-5 col-lg-4 blacklight-lc_call_number_display mb-0"
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

  # Safely converts a single or multi-value solr field
  # to a string. Mult values are concatenated with a ', ' by default
  # @param document - A solr document object
  # @param field - the name of a solr field
  # @param joiner - the string to use to concatenate multivalue fields
  def solr_field_to_s(document, field, joiner = ", ")
    Array.wrap(document.fetch(field, [])).join(joiner)
  end

  def _build_guest_login_libwizard_url(document)
    doc_params =
    {
      "rft.title" => solr_field_to_s(document, "title_statement_display"),
      "rft.date" => solr_field_to_s(document, "pub_date"),
      "edition" => solr_field_to_s(document, "edition_display"),
      # "volume" => solr_field_to_s(document, "edition_display"),
    }
    sid = solr_field_to_s(document, "id")
    if sid.present?
      doc_params["rft_id"] = "https://librarysearch.temple.edu/catalog/#{sid}"
    end
    doc_params.select! { |k, v| v.present? }
    URI::HTTPS.build(host: "temple.libwizard.com",
      path: "/f/ContinueAsGuest", query: doc_params.to_query).to_s
  end

  def _build_libwizard_url(document)
    doc_params =
    {
      "rft.title" => solr_field_to_s(document, "title_statement_display"),
      "rft.date" => solr_field_to_s(document, "pub_date"),
      "edition" => solr_field_to_s(document, "edition_display"),
      "rft.isbn" => solr_field_to_s(document, "isbn_display"),
      "rft.issn" => solr_field_to_s(document, "issn_display"),
      "rft.oclcnum" => solr_field_to_s(document, "oclc_display"),
      "rft.pub" => [
        solr_field_to_s(document, "imprint_display"),
        solr_field_to_s(document, "imprint_prod_display"),
        solr_field_to_s(document, "imprint_dist_display"),
        solr_field_to_s(document, "imprint_man_display"),
      ].select(&:present?).join(", "),
    }
    sid = solr_field_to_s(document, "id")
    if sid.present?
      doc_params["rft_id"] = "https://librarysearch.temple.edu/catalog/#{sid}"
    end
    doc_params.select! { |k, v| v.present? }
    URI::HTTPS.build(host: "temple.libwizard.com",
      path: "/f/LibrarySearchRequest", query: doc_params.to_query).to_s
  end

  def digital_help_allowed?(document)
    document.fetch("availability_facet", [])
      .include?("At the Library") &&
    document.fetch("format", [])
      .exclude?("Archival Material") &&
    document.fetch("format", [])
      .exclude?("Object") &&
    !document["electronic_resource_display"] &&
    !hathitrust_link_allowed?(document)
  end

  def open_shelves_allowed?(document)
    {
      "MAIN"     => ["hirsh", "juvenile", "leisure", "stacks", "newbooks"],
      "AMBLER"   => ["aleisure", "imc", "newbooks", "oversize", "reference", "stacks"],
      "POD"      =>  ["stacks"]
    }.any? { |library_code, locations| check_open_shelves(document, library_code, locations) }
  end

  def check_open_shelves(document, library_code, locations)
    document.fetch("items_json_display", []).any? { |item|
      item["current_library"].include?(library_code) &&
      locations.include?(item["current_location"])
    }
  end

  def build_hathitrust_url(field)
    record_id = field.fetch("bib_key", nil)
    return if record_id.nil?
    URI::HTTPS.build(host: "catalog.hathitrust.org",
      path: "/Record/#{record_id}",
      query: "signon=swle:https://fim.temple.edu/idp/shibboleth"
    ).to_s
  end

  def render_hathitrust_link(ht_bib_key_field)
    render "hathitrust_link", ht_bib_key_field: ht_bib_key_field
  end

  def hathitrust_link_allowed?(document)
    ht_bib_key_field = document.fetch("hathi_trust_bib_key_display", []).first rescue nil
    ht_bib_key_field.fetch("access", "deny") == "allow" rescue nil
  end

  def render_hathitrust_display(document)
    ht_bib_key_field = document.fetch("hathi_trust_bib_key_display", []).first rescue nil
    return if ht_bib_key_field.nil?
    online_resources = []
    online_resources << render_hathitrust_link(ht_bib_key_field)

    if (campus_closed? || hathitrust_link_allowed?(document))
      render "online_availability", online_resources: online_resources
    end
  end

  def render_hathitrust_button(document)
    ht_bib_key_field = document.fetch("hathi_trust_bib_key_display", []).first rescue nil
    return if ht_bib_key_field.nil?
    link = render_hathitrust_link(ht_bib_key_field)

    if (campus_closed? || hathitrust_link_allowed?(document))
      render "hathitrust_button", document: document, links: link
    end
  end

  def render_purchase_order_availability(presenter)
    doc = presenter.document
    return unless doc.purchase_order?


    field = presenter.send(:fields)["purchase_order_availability"]

    if field.with_panel
      rows = [ t("purchase_order.purchase_order_allowed") ]
      render partial: "availability_panel", locals: { label: field.label, rows: rows }

    elsif current_user && !current_user.can_purchase_order?
      content_tag :div, t("purchase_order.purchase_order_allowed"), class: "availability border border-header-grey"
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
      content_tag :div, link, class: "requests-container mb-2 ml-0"
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
    when "title_uniform_display", "title_addl_display", "relation"
      { search_field: "title", q: query }
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

  # [a, b, c] => [[a], [a, b], [a, b, c]]
  def hierarchies(array)
    count = 0
    array.reduce([]) { |acc, value| acc << array.slice(0, count += 1) }
  end

  def subject_link(subject, label = nil)
    label ||= subject
    link_to(label, "#{base_path}?f[subject_facet][]=#{CGI.escape subject}", class: "search-subject", title: "Search: #{subject}")
  end

  # A hierarchical_subject is just a string array.
  def hierarchical_subject_link(hierarchical_subject)
    label = hierarchical_subject.last
    subject = hierarchical_subject.join(" — ")

    subject_link(subject, label)
  end

  def subject_links(args)
    separator = content_tag(:span, content_tag(:span, " — ", class: ""), class: "subject-level")

    args[:document][args[:field]].uniq
      .map { |subj| subj.sub("— — ", "— ") } # TODO: Do we still need this step?
      .map { |subj| subj.split(" — ") }
      .map(&method(:hierarchies))
      .map { |h_subjs| h_subjs.map(&method(:hierarchical_subject_link)).join(separator).html_safe }
  end

  def genre_links(args)
    args[:document][args[:field]].uniq.map do |genre|
      link_to(genre, "#{search_catalog_path}?f[genre_full_facet][]=#{CGI.escape genre}")
    end
  end

  def database_subject_links(args)
    args[:document][args[:field]].map do |subject|
      link_to(subject.sub("— — ", "— "), "#{base_path}?f[az_subject_facet][]=#{CGI.escape subject}")
    end
  end


  def database_type_links(args)
    args[:document][args[:field]].map do |type|
      link_to(type.sub("— — ", "— "), "#{base_path}?f[az_format][]=#{CGI.escape type}", class: "p-2")
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
    content_tag(:div, link_to(text, url, title: "Target opens in new window", target: "_blank"), class: "electronic_links online-list-items")
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

    content_tag(:div, item_html , class: " electronic_links online-list-item")
  end

  def service_unavailable_fields
    [ "service_temporarily_unavailable", "service_unavailable_date", "service_unavailable_reason" ]
  end

  def electronic_notes(type)
    name = "#{type}_notes"

    Rails.cache.fetch(name) do
      JsonStore.find_by(name: name)&.value || {}
    end
  end

  def get_collection_notes(id)
    (electronic_notes("collection")[id] || {})
      .except(*service_unavailable_fields)
      .values.select(&:present?)
  end

  def get_service_notes(id)
    (electronic_notes("service")[id] || {})
      .except(*service_unavailable_fields)
      .values.select(&:present?)
  end

  def get_unavailable_notes(id)
    (electronic_notes("service")[id] || {})
      .slice("service_unavailable_reason")
      .select { |k, v| v.present? }.values
      .map { |reason| "This service is temporarily unavailable due to: #{reason}." }
  end

  def render_electronic_notes(field)
    collection_id = field["collection_id"]
    service_id = field["service_id"]

    public_notes = field["public_note"]
    collection_notes = get_collection_notes(collection_id)
    service_notes = get_service_notes(service_id)
    unavailable_notes = get_unavailable_notes(service_id)

    if collection_notes.present? ||
        service_notes.present? ||
        public_notes.present? ||
        unavailable_notes.present?

      render partial: "electronic_notes", locals: {
        collection_notes: collection_notes,
        service_notes: service_notes,
        public_notes: public_notes,
        unavailable_notes: unavailable_notes,
      }
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

  def render_bookmark_partial(options = {}, &block)
    bookmark_partial = blacklight_config.navbar.partials
    .select { |name| name == :bookmark }

    render_filtered_partials(bookmark_partial, &block)
  end

  def ez_borrow_list_item(controller_name)
    if controller_name == "catalog"
      content_tag(:li, t("no_results.ez_borrow_html", href: link_to(t("no_results.ez_borrow_href"), t("no_results.ez_borrow_link"), target: "_blank")))
    end
  end

  def campus_closed?
    ::FeatureFlags.campus_closed?(params)
  end

  def with_libguides?
    ::FeatureFlags.with_libguides?(params)
  end

  def with_libkey?
    ::FeatureFlags.with_libkey?(params)
  end

  def derived_lib_guides_search_term(response)
    LibGuidesApi.derived_lib_guides_search_term(response, params.fetch("q", ""))
  end
end
