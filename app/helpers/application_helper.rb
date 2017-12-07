# frozen_string_literal: true

module ApplicationHelper
  def render_location(value)
    Rails.configuration.locations[value]
  end

  def render_location_show(value)  # why do we get the entire solr document in show fields?
    render_location(value[:value].first)
  end

  def get_search_params(field, query)
    if field == "subject_display"
      { controller: "catalog", action: "index", search_field: "subject", q: query.gsub(/>|—/, "") }
    else
      { controller: "catalog", action: "index", search_field: field, q: query }
    end
  end

  def fielded_search(query, field)
    params = get_search_params(field, query)
    link_url = search_action_path(params)
    link_to(query, link_url)
  end

  def list_with_links(args)
    args[:document][args[:field]].map { |field| content_tag(:li,  fielded_search(field, args[:field]), class: "list_items") }.join("<br /> ").html_safe
  end

  def browse_creator(args)
    creator = args[:document][args[:field]]
    creator.each_with_index do |name, i|
      content_tag :ul do
        newname = link_to(name, root_url + "/?f[creator_facet][]=#{name}", class: "list_items")
        creator = newname.html_safe
      end
    end
    list_with_links(args)
  end

  def check_for_full_http_link(args)
    args[:document][args[:field]].map { |field|
      if field.include?("http")
        electronic_access_links(field)
      else
        electronic_resource_link_builder(field)
      end
    }.join("<br />").html_safe
  end

  def electronic_access_links(field)
    link_text = field.split("|").first.sub(/ *[ ,.\/;:] *\Z/, "")
    link_url = field.split("|").last
    new_link = content_tag(:li, link_to(link_text, link_url, class: "list_items"))
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
    link_to(db_name, alma_electronic_resource_direct_link(portfolio_pid))
  end

  def alma_electronic_resource_direct_link(portfolio_pid)
    query = {
        'u.ignore_date_coverage': "true",
        'Force_direct': true,
        portfolio_pid: portfolio_pid
    }
    alma_build_openurl(query)
  end

  def electronic_resource_list_item(portfolio_pid, db_name, addl_info)
    item_parts = [render_alma_eresource_link(portfolio_pid, db_name), addl_info]
    item_html = item_parts.compact.join(" - ").html_safe
    content_tag(:li, item_html , class: "list_items")
  end

  def electronic_resource_link_builder(field)
    return if field.empty?
    portfolio_pid, db_name, addl_info = field.split("|")
    db_name ||= "Find it online"
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

  def bento_engine_nice_name(engine_id)
    I18n.t("bento.#{engine_id}.nice_name")
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
    if document["location_display"].include?("rarestacks") && document["library_facet"].include?("Special Collections Research Center")
      button_to("Request to View in Reading Room", aeon_request_url(document), class:"aeon-request btn btn-primary") +
      content_tag(:p, "For materials from the Special Collections Research Center only", class: "aeon-text")
    end
  end

  def bento_link_to_full_results(results)
    if results.engine_id.include?("blacklight")
  	   link_to "See all #{number_with_delimiter(results.total_items)} results.", search_catalog_path(:q => params[:q]), class: "full-results"
  	else
      content_tag(:p, "Total records from #{bento_engine_nice_name(results.engine_id)}: #{results.count}" || '?', class: "record-count")

    end
  end
end
