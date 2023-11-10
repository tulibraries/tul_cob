# frozen_string_literal: true

module CatalogHelper
  include Blacklight::CatalogHelperBehavior
  include HathitrustHelper

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
        "journal_article" => "journal_periodical",
        "legal_document" => "legal",
        "market_research" => "dataset",
        "microform" => "legal",
        "newsletterarticle" => "legal",
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

  def render_lc_display_field(field_presenter)
    content_tag :dl, nil, class: "dl-horizontal document-metadata blacklight-lc_call_number_display  mb-0" do
      html = content_tag :dt, "LC Classification:", class: "index-label blacklight-lc_call_number_display"
      html += content_tag :dd, field_presenter.render, class: "blacklight-lc_call_number_display"
    end
  end

  # Overridden from module Blacklight::BlacklightHelperBehavior.
  # Create <link rel="alternate"> links from a documents dynamically provided export formats.
  # Returns empty string if no links available.
  # Overridden in order to disable rel alternate links added to page headers.
  def render_link_rel_alternates(document = @document, options = {})
    ""
  end

  def advanced_catalog_search_path
    params = @search_state.to_h.select { |k, v| !["page"].include? k }
    blacklight_advanced_search_engine.advanced_search_path(params)
  end

  # Safely converts a single or multi-value solr field
  # to a string. Mult values are concatenated with a ', ' by default
  # @param document - A solr document object
  # @param field - the name of a solr field
  # @param joiner - the string to use to concatenate multivalue fields
  def doc_field_joiner(document, field, joiner = ", ")
    Array.wrap(document.fetch(field, [])).join(joiner)
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

  def get_search_params(field, query)
    case field
    when "title_uniform_display", "title_addl_display", "relation"
      { search_field: "title", q: %Q("#{query}") }
    else
      { search_field: field, q: query }
    end
  end

  def fielded_search(query, field)
    params = get_search_params(field, query)
    link_url = search_action_path(params)
    title = params[:title] || query
    link_to(title, link_url)
  end

  def list_with_links(args)
    args[:document][args[:field]].map { |field| content_tag(:li,  fielded_search(field, args[:field]), class: "list_items") }.join("").html_safe
  end

  def additional_title_link(args)
    args[:document][args[:field]].map do |title_data|
      title_data = JSON.parse(title_data)

      linked_subfields = title_data["title"]
      relation_to_work_prefix = title_data["relation"]
      next if linked_subfields.blank?

      link = fielded_search(linked_subfields, args[:field])

      content_tag(:li, class: "list_items") do
        if relation_to_work_prefix.present?
          link.prepend("#{relation_to_work_prefix} ")
        else
          link
        end
      end
    end
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

  def record_page_ms_links(args)
    linked_field = [args[:field]].first
    args[:document][args[:field]].uniq.map do |field|
      link_to(field, "#{search_catalog_path}?f[#{linked_field}][]=#{CGI.escape field}")
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
      content_tag(:li, t("no_results.ez_borrow_html", href: link_to(t("no_results.ez_borrow_href"), ez_borrow_link_keyword(t("no_results.ez_borrow_link")), target: "_blank")))
    end
  end

  def ez_borrow_link_keyword(url)
    uri = URI.parse(url)
    query = "#{params[:q]}"

    URI::HTTPS.build(
      host: uri.host,
      path: "/Search/Results",
      query: URI.encode_www_form({
        "lookfor" => query,
        "type" => "AllFields"
      })).to_s
  end

  def campus_closed?
    ::FeatureFlags.campus_closed?(params)
  end

  def with_libguides?
    ::FeatureFlags.with_libguides?(params)
  end

  def derived_lib_guides_search_term(response)
    LibGuidesApi.derived_lib_guides_search_term(response, params.fetch("q", ""))
  end

  def join(args)
    return args[:value].join("\n")
  end
end
