# frozen_string_literal: true

# Application Controller.
class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Blacklight::BlacklightHelperBehavior

  layout "blacklight"

  protect_from_forgery with: :exception

  # Rails 5.1 and above requires permitted params to be defined in the Controller
  # BL doesn't do that, but might in the future. This allows us to use the pre 5.1
  # behavior until we can define all possible param  in the future.
  ActionController::Parameters.permit_all_parameters = true


  impersonates :user unless Rails.env.production?

  helper_method :should_show_spellcheck_suggestions?

  # Overrides Devise::Controllers::Helpers#after_sign_out_path_for
  #
  # We want to make sure user actually gets signed out.
  # @see BL-224
  def after_sign_out_path_for(resource_or_scope)
    Rails.configuration.devise[:sign_out_redirect_url]
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

  protected
    def after_sign_in_path_for(resource)
      sign_in_url = helpers.new_user_with_redirect_path
      if request.referer == sign_in_url ||
          request.referer == request.env["HTTP_ORIGIN"] + sign_in_url
        super
      else
        stored_location_for(resource) || request.referer || root_path
      end
    end
end
