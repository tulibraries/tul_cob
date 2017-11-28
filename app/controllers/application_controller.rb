# frozen_string_literal: true

# Application Controller.
class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout "blacklight"

  protect_from_forgery with: :exception

  before_action do
    binding.pry
    blacklight_config.add_nav_action(:library_account, partial: "#{root_path}/users/account_link")
  end
end
