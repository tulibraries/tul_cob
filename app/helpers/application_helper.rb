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

  def fielded_search(query, field)
    params = get_search_params(field, query)
    link_url = search_action_path(params)
    link_to(query, link_url)
  end

  def get_search_params(field, query)
    #Remove > for links and replace with blank.
    {:controller => "catalog", :action => 'index', :search_field => field, :q=> query }
  end
end
