# frozen_string_literal: true

# Application Controller.
class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  layout "blacklight"

  protect_from_forgery with: :exception

  impersonates :user unless Rails.env.production?

  before_action do
    blacklight_config.add_nav_action(
      :library_account,
      partial: "/users/account_link"
    )
  end
end
