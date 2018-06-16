# frozen_string_literal: true

module ApplicationHelper
  def render_location(value)
    Rails.configuration.locations[value]
  end

  def render_location_show(value)  # why do we get the entire solr document in show fields?
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
    args[:document][args[:field]].map { |field|
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

  def aeon_request_url(document)
    form_fields = {
         ItemTitle: "title_statement_display",
         ItemPlace: "imprint_display",
         ReferenceNumber: "alma_mms_display",
         CallNumber: "call_number_display",
         ItemAuthor: "creator_display"
     }

    openurl_field_values = form_fields.map { |k, k2|
      [k, document[k2].to_s.delete('[]""')] }.to_h

    openurl_field_values["Action"] = 10
    openurl_field_values["Form"] = 30


    URI::HTTPS.build(
      host:  "temple.aeon.atlas-sys.com",
      path: "/Logon/",
      query: openurl_field_values.to_query).to_s
  end

  def aeon_request_button(document)
    if document.fetch("location_display", []).include?("SCRC rarestacks") && document["library_facet"].include?("Special Collections Research Center")
      button_to("Request to View in Reading Room", aeon_request_url(document), class: "aeon-request btn btn-primary") +
      content_tag(:p, "For materials from the Special Collections Research Center only", class: "aeon-text")
    end
  end

  def total_items(results)
    results.total_items[:query_total] || 0 rescue 0
  end

  def total_online(results)
    results.total_items[:online_total] || 0 rescue 0
  end

  # TODO: Is variation here better handled in multiple link templates?
  def bento_link_to_full_results(results)
    total = number_with_delimiter(total_items results)
    case results.engine_id
    when "blacklight"
      url = search_catalog_path(q: params[:q])
      link_to "View all #{total} items", url, class: "full-results"
    when "journals"
      url = search_catalog_path(q: params[:q], f: { format: ["Journal/Periodical"] })
      link_to "View all #{total} journals", url, class: "full-results"
    when "books"
      url = search_catalog_path(q: params[:q], f: { format: ["Book"] })
      link_to "View all #{total} books", url, class: "full-results"
    when "more"
      url = search_catalog_path(q: params[:q])
      link_to "View all catalog results", url, class: "full-results"
    when "articles"
      url = url_for(action: :index, controller: :primo_central, q: params[:q])
      link_to "View all #{total} articles", url, class: "full-results"
    else
      content_tag(:p, "Total records from #{bento_engine_nice_name(results.engine_id)}: #{total}" || "?", class: "record-count")
    end
  end

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
    when "more"
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
      content_tag(:h1, "Catalog Search", class: "nav-header")
    elsif params[:controller] == "primo_central" || params[:controller] == "primo_advanced"
      content_tag(:h1, "Articles Search", class: "nav-header")
    end
  end

  def navigational_links
    if navigational_headers.present?
      if navigational_headers.include?("Catalog Search")
        link_to("Articles Search", search_path, class: "btn btn-primary nav-btn")
      elsif navigational_headers.include?("Articles Search")
        link_to("Catalog Search", search_catalog_path, class: "btn btn-primary nav-btn")
      end
    end
  end

  def render_online_only_checkbox
    online_articles = params.dig("f", "tlevel")&.include?("online_resources")
    online_catalog = params.dig("f", "availability_facet")&.include?("Online")
    checked = online_articles || online_catalog

    check_box_tag "online_only", "yes", checked, onclick: "toggleOnlineOnly()"
  end
end
