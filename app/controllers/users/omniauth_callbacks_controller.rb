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
    next_url = params[:next] || "user#account"
    @user = User.from_omniauth(request.env["omniauth.auth"])
    sign_in(:user, @user)
    session[:alma_auth_type] = "sso"
    session[:alma_sso_user] = @user.uid
    session[:alma_sso_token] = SecureRandom.hex(10)
    set_flash_message(:success, :notice, kind: "Temple Single Sign On") if is_navigational_format?
    redirect_to users_url(@user), action: :account
  end

  def failure
    redirect_to root_path
  end
end
