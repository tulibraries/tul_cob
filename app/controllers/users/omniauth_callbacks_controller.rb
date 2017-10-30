# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: :alma

  def alma
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(request.env["omniauth.auth"])
    set_flash_message(:notice, :success, kind: "Alma") if is_navigational_format?
    sign_in_and_redirect @user, event: :authentication #this will throw if @user is not activated
  end

  def shibboleth
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(request.env["omniauth.auth"])
    set_flash_message(:notice, :success, kind: "Shibboleth") if is_navigational_format?
    sign_in_and_redirect @user, event: :authentication #this will throw if @user is not activated
  end

  def failure
    redirect_to root_path
  end
end
