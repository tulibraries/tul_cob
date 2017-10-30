module ApplicationHelper

  def render_location(value)
    Rails.configuration.locations[value]
  end

  def render_location_show(value)  # why do we get the entire solr document in show fields?
    render_location(value[:value].first)
  end

  def get_search_params(field, query)
    if field == 'subject_display'
      { :controller => "catalog", :action => 'index', :search_field => 'subject', :q=> query.gsub(/>|—/, '') }
    else
      { :controller => "catalog", :action => 'index', :search_field => field, :q=> query }
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
    args[:document][args[:field]].each_with_index do |name, i|
      content_tag :ul do
      newname = link_to(name, root_url + "/?f[creator_facet][]=#{name}", class: "list_items")
      args[:document][args[:field]][i] = newname.html_safe
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
    link_text = field.split("|").first.sub(/ *[ ,.\/;:] *\Z/, '')
    link_url = field.split("|").last
    new_link = content_tag(:li, link_to(link_text, link_url, class: "list_items"))
    new_link
  end

  def alma_build_openurl(query)
    query_defaults = {
      rfr_id: 'info:sid/primo.exlibrisgroup.com',
    }

    URI::HTTPS.build(
        host: alma_domain,
        path: "/view/uresolver/#{alma_institution_code}/openurl",
        query: query_defaults.merge(query).to_query).to_s
  end

  def alma_electronic_resource_direct_link(portfolio_pid)
    query = {
        'u.ignore_date_coverage': 'true',
        'Force_direct': true,
        portfolio_pid: portfolio_pid
    }
    alma_build_openurl(query)
  end

  def electronic_resource_link_builder(field)
    electronic_resource_from_traject = field.split("|")
    portfolio_pid = electronic_resource_from_traject.first
    database_name = electronic_resource_from_traject.second || "Find it online"
    additional_info = electronic_resource_from_traject.last
      new_link = content_tag(:li, link_to(database_name, alma_electronic_resource_direct_link(portfolio_pid)), class: "list_items")
    new_link 
  end

  def single_link_builder(field)
    electronic_resource_from_traject = field.split("|")
    portfolio_pid = electronic_resource_from_traject.first
    alma_electronic_resource_direct_link(portfolio_pid)
  end

  def bento_engine_nice_name(engine_id)
    I18n.t("bento.#{engine_id}.nice_name")
  end
end
