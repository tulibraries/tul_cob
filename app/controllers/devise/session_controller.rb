# frozen_string_literal: true

class Devise::SessionController < DeviseController
  # Overrides Devise::Controllers::Helpers#after_sign_out_path_for
  #
  # We want to make sure user actually gets signed out.
  # @see BL-224
  def after_sign_out_path_for(resource_or_scope)
    Rails.configuration.devise[:sign_out_redirect_url]
  end
end
