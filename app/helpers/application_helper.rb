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
    content_tag :ul do
      args[:document][args[:field]].map { |field| content_tag(:li,  fielded_search(field, args[:field]), class: "list_items") }.join("<br /> ").html_safe
    end
  end
<<<<<<< HEAD
  
  def browse_creator(args)
    args[:document][args[:field]].each_with_index do |name, i|
      content_tag :ul do
      newname = link_to(name, "/?f[creator_facet][]=#{name}", class: "list_items")
      args[:document][args[:field]][i] = newname.html_safe
      end
    end
  end
=======












>>>>>>> BL-6 Links to resources working

  def electronic_access_links(args)
    content_tag :ul do
      new_link = args[:document][args[:field]].each_with_index.map { |field, i|
        content_tag(:li, link_to(args[:value][i].split("|").first.sub(/ *[ ,.\/;:] *\Z/, ''), args[:value][i].split("|").last), class: "list_items") }
      new_link.join("<br />").html_safe
    end
  end
end
