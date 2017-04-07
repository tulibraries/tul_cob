module ApplicationHelper

  def render_location(value)
    Rails.configuration.locations[value]
  end

  def render_location_show(value)  # why do we get the entire solr document in show fields?
    render_location(value[:value].first)
  end

end
