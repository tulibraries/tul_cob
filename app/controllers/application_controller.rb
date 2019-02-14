# frozen_string_literal: true

# Application Controller.
class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Blacklight::BlacklightHelperBehavior
  include JsonLogger

  layout "blacklight"

  protect_from_forgery with: :exception

  rescue_from ActionController::InvalidAuthenticityToken,
    with: :redirect_to_referer

  skip_after_action :discard_flash_if_xhr

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

  ##
  # Overrides Blacklight::BlacklightHelperBehavior::should_show_spellcheck_suggestions?.
  #
  # Overridden because the spelling field is not always available.
  #
  # @see: https://github.com/projectblacklight/blacklight/pull/1845
  #
  # @param [Blacklight::Solr::Response] response
  # @return [Boolean]
  def should_show_spellcheck_suggestions?(response)
    response.total <= spell_check_max &&
      !response.spelling.nil? &&
      response.spelling.words.any?
  end

  def redirect_to_referer
    flash[:notice] = "Your search results page had to be reloaded. Please try again."
    redirect_to request.referer
  end

  protected

    def no_cache
      response.headers["Cache-Control"] = "no-cache, no-store"
      response.headers["Pragma"] = "no-cache"
      response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
    end
end
