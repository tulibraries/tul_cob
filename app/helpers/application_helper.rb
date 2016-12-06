module ApplicationHelper

  require 'pry'

  def render_location(value)
    Rails.configuration.locations[value]
  end
end
