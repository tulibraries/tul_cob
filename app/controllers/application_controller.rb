# frozen_string_literal: true

# Application Controller.
class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Blacklight::BlacklightHelperBehavior
  include Blacklight::ConfigurationHelperBehavior
  include JsonLogger

  layout "blacklight"

  protect_from_forgery with: :exception

  before_action :get_manifold_alerts, only: [
    :index, :show, :not_found, :internal_server_error,
    :account, :librarian_view, :citation, :email, :sms
  ]

  rescue_from ActionController::InvalidAuthenticityToken,
    with: :redirect_to_referer

  # Rails 5.1 and above requires permitted params to be defined in the Controller
  # BL doesn't do that, but might in the future. This allows us to use the pre 5.1
  # behavior until we can define all possible param  in the future.
  ActionController::Parameters.permit_all_parameters = true

  helper_method :should_show_spellcheck_suggestions?

  # Overrides Devise::Controllers::Helpers#after_sign_out_path_for
  #
  # We want to make sure user actually gets signed out.
  # @see BL-224
  def after_sign_out_path_for(resource_or_scope)
    if request.params[:type] == "sso"
      Rails.configuration.devise[:sign_out_redirect_url]
    else
      super
    end
  end

  def redirect_to_referer
    flash[:notice] = "Your search results page had to be reloaded. Please try again."
    redirect_to request.referer
  end

  def get_manifold_alerts
    alert_url = "https://library.temple.edu/alerts.json"

    @manifold_alerts_thread ||= Thread.new {
      Rails.cache.fetch("manifold_alerts", expires_in: 5.minutes) do
        resp = begin
                 HTTParty.get(alert_url, timeout: 1)
               rescue => e
                 Honeybadger.notify(e)
                 Thread.new { sleep 0.25; Rails.cache.delete("manifold_alerts") }
                 {}
               end
        resp["data"] || []
      end
    }
  end

  protected

    def no_cache
      response.headers["Cache-Control"] = "no-store"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end

    # ensure that rails treats request as xhr
    def xhr!
      request.headers["HTTP_X_REQUESTED_WITH"] = "XMLHttpRequest"
    end
end
