module ApplicationHelper

  def render_location(value)
    Rails.configuration.locations[value]
  end

  def render_location_show(value)  # why do we get the entire solr document in show fields?
    render_location(value[:value].first)
  end

  def list(args)
    content_tag :ul do
      args[:document][args[:field]].map { |field| content_tag(:li, field, class: "list_items") }.join("<br /> ").html_safe
    end
  end

  def get_search_params(field, query)
    if field == 'creator_display'
      { :controller => "catalog", :action => 'index', :search_field => 'creator', :q=> query }
    elsif field == 'subject_display'
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
    content_tag :ul do
      args[:document][args[:field]].map { |field| content_tag(:li,  fielded_search(field, args[:field]), class: "list_items") }.join("<br /> ").html_safe
    end
  end
end
