# frozen_string_literal: true

module ApplicationHelper
  # value ex: "MAIN stacks"
  def render_location(value)
    params = value.to_s.split
    [ Rails.configuration.libraries[params.first],
      Rails.configuration.locations.dig(*params) ]
      .compact
      .join(" ")
  end

  def render_location_show(value)
    render_location(value[:value].first)
  end

  def get_search_params(field, query)
    case field
    when "subject_display"

      { search_field: "subject", q: query.gsub(/>|—/, ""), title: query }
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

  def has_one_electronic_resource?(document)
    document.fetch("electronic_resource_display", []).length == 1
  end

  def has_many_electronic_resources?(document)
    document.fetch("electronic_resource_display", []).length > 1
  end

  def check_holdings_library_name(document)
    document.fetch("holdings_with_no_items_display", []).map(&:split).to_h.keys
  end

  def check_holdings_call_number(document)
    document.fetch("call_number_display", []).first
  end

  def check_holdings_location(document, library)
    locations_array = []
    locations = document.fetch("holdings_with_no_items_display", []).select { |location| location.include?(library) }.map { |field| field.split() }
    locations.each { |k, v|
      shelf = Rails.configuration.locations.dig(k, v)
      locations_array << shelf
    }
    locations_array
  end

  def check_for_full_http_link(args)
    [args[:document][args[:field]]].flatten.compact.map { |field|
      if field.include?("http")
        electronic_access_links(field)
      else
        electronic_resource_link_builder(field)
      end
    }.join("").html_safe
  end

  def electronic_access_links(field)
    link_text = field.split("|").first.sub(/ *[ ,.\/;:] *\Z/, "")
    link_url = field.split("|").last
    new_link = content_tag(:td, link_to(link_text, link_url, title: "Target opens in new window", target: "_blank"), class: "electronic_links list_items")
    new_link
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

  def electronic_resource_list_item(portfolio_pid, db_name, addl_info)
    item_parts = [render_alma_eresource_link(portfolio_pid, db_name), addl_info]
    item_html = item_parts.compact.join(" - ").html_safe
    content_tag(:td, item_html , class: " electronic_links list_items")
  end

  def electronic_resource_link_builder(field)
    return if field.empty?
    portfolio_pid, db_name, addl_info, availability = field.split("|")
    return if availability == "Not Available"
    db_name ||= "Find it online"
    addl_info = nil if addl_info&.empty?
    electronic_resource_list_item(portfolio_pid, db_name, addl_info)
  end

  def single_link_builder(field)
    if field.include?("http")
      field.split("|").last
    else
      electronic_resource_from_traject = field.split("|")
      portfolio_pid = electronic_resource_from_traject.first
      alma_electronic_resource_direct_link(portfolio_pid)
    end
  end

  def bento_single_link(field)
    electronic_resource = field.first.split("|")
    portfolio_pid = electronic_resource.first
    alma_electronic_resource_direct_link(portfolio_pid)
  end

  def bento_engine_nice_name(engine_id)
    I18n.t("bento.#{engine_id}.nice_name")
  end

  def bento_icons(engine_id)
    case engine_id
    when "books"
      content_tag(:span, "", class: "bento-icon bento-book")
    when "articles"
      content_tag(:span, "", class: "bento-icon bento-article")
    when "journals"
      content_tag(:span, "", class: "bento-icon bento-journal")
    when "more"
      content_tag(:span, "", class: "bento-icon bento-more")
    end
  end

  def aeon_request_url(item)
    form_fields = {
         ItemTitle: item.item.dig("bib_data", "title"),
         ItemPlace: item.item.dig("bib_data", "place_of_publication") + " " + item.item.dig("bib_data", "publisher_const") + " " + item.item.dig("bib_data", "date_of_publication"),
         ReferenceNumber: item.item.dig("bib_data", "mms_id"),
         CallNumber: item.call_number,
         ItemAuthor: item.item.dig("bib_data", "author")
     }
     
    openurl_field_values = form_fields.map { |k, v|
      [k, v.to_s.delete('[]""')] }.to_h

    openurl_field_values["Action"] = 10
    openurl_field_values["Form"] = 30


    URI::HTTPS.build(
      host:  "temple.aeon.atlas-sys.com",
      path: "/Logon/",
      query: openurl_field_values.to_query).to_s
  end

  def aeon_request_button(items)
    raw items.map { |item|
      if item.library.include?("SCRC") && item.location.include?("rarestacks")
        link_to("Request to View in Reading Room", aeon_request_url(item), class: "accordian-toggle")
      end
    }.join
  end

  def total_items(results)
    results.total_items[:query_total] || 0 rescue 0
  end

  def total_online(results)
    results.total_items[:online_total] || 0 rescue 0
  end

  def bento_link_to_full_results(results)
    total = number_with_delimiter(total_items results)
    BentoSearch.get_engine(results.engine_id).view_link(total, self)
  end

  # TODO: move to decorator or eninge class.
  def bento_link_to_online_results(results)
    total = number_with_delimiter(total_online results)
    case results.engine_id
    when "blacklight"
      url = search_catalog_path(q: params[:q], f: { availability_facet: ["Online"] })
      link_to "View all #{total} online items", url, class: "full-results"
    when "journals"
      url = search_catalog_path(q: params[:q], f: {
        format: ["Journal/Periodical"],
        availability_facet: ["Online"]
      })
      link_to "View all #{total} online journals", url, class: "full-results"
    when "books"
      url = search_catalog_path(q: params[:q], f: {
        format: ["Book"],
        availability_facet: ["Online"]
      })
      link_to "View all #{total} ebooks", url, class: "full-results"
    when "more", "resource_types"
      ""
    when "articles"
      url = url_for(
        action: :index, controller: :primo_central,
        q: params[:q], f: { availability_facet: ["Online"] }
      )
      link_to "View all #{total} online articles", url, class: "full-results"
    else
      ""
    end
  end

  # Gets the base_path of current_page (i.e. /articles if at /articles/foobar)
  def base_path
    File.dirname(url_for)
  end

  # Render the index field (link)
  def index_field_url_link(arg)
    url = arg[:value].first
    link_to "direct link", url, remote: true
  end

  def navigational_headers
    if params[:controller] == "catalog" || params[:controller] == "advanced"
      label = link_to("Catalog Search", search_catalog_path, id: "catalog_header")
    elsif params[:controller] == "primo_central" || params[:controller] == "primo_advanced"
      label = link_to("Articles Search", search_path, id: "articles_header")
    end
    # content_tag(:h1, label, class: "nav-header")
  end

  def navigational_links
    if navigational_headers.present?
      if navigational_headers.include?("Catalog Search")
        link_to("Articles Search", search_path, class: "btn btn-primary nav-btn", id: "articles_button")
      elsif navigational_headers.include?("Articles Search")
        link_to("Catalog Search", search_catalog_path, class: "btn btn-primary nav-btn", id: "cataog_button")
      end
    end
  end

  def render_online_only_checkbox
    online_articles = params.dig("f", "tlevel")&.include?("online_resources")
    online_catalog = params.dig("f", "availability_facet")&.include?("Online")
    checked = online_articles || online_catalog

    check_box_tag "online_only", "yes", checked, onclick: "toggleOnlineOnly()", id: "online-only"
  end

  def login_disabled?
    Rails.configuration.features.fetch(:login_disabled, false)
  end

  def render_saved_searches?
    false
  end
  def render_search_history?
    false
  end
end
