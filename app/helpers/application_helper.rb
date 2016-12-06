module ApplicationHelper

  def render_location(value)
    Rails.configuration.locations[value]
  end
end
