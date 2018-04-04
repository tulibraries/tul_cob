# frozen_string_literal: true

# Application Controller.
class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller
  include Blacklight::Controller
  include Blacklight::BlacklightHelperBehavior

  layout "blacklight"

  protect_from_forgery with: :exception

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
end
