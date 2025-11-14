# frozen_string_literal: true

module CatalogHelper
  include Blacklight::CatalogHelperBehavior
  include HathitrustHelper

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

  def advanced_catalog_search_path
    params = @search_state.to_h.select { |k, v| !["page"].include? k }
    blacklight_advanced_search_engine.advanced_search_path(params)
  end

  def render_email_form_field
    if !current_user&.email
      render partial: "email_form_field"
    end
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
    sanitized_title = sanitize(title)
    link_to(sanitized_title, link_url)
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
    separator = content_tag(:a, " — ", { class: "subject-level", aria: { hidden: true } })

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

  def derived_lib_guides_search_term(response)
    LibGuidesApi.derived_lib_guides_search_term(response, params.fetch("q", ""))
  end

  # Delegation method for Blacklight configuration compatibility
  # This allows the existing helper_method: :separate_formats to continue working
  def separate_formats(args)
    # Create a mock document with the format field for the decorator
    document_data = { format: args[:value] }
    DocumentDecorator.new(document_data).separate_formats
  end

  def join(args)
    return args[:value].join("\n")
  end

  # Rails 7.2's Zeitwerk reloading no longer guarantees
  # Blacklight::UrlHelperBehavior stays mixed into CatalogHelper,
  # so templates calling show_solr_document_url would raise. Delegating to
  # solr_document_url keeps the existing templates working regardless of
  # how the helper modules are reloaded. Even though no template in our
  # repo mentions it, the upstream Blacklight views/translations still
  # expect it to exist.
  def show_solr_document_url(document, *args, **kwargs)
    solr_document_url(document, *args, **kwargs)
  end
end
