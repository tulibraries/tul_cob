# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  protect_from_forgery with: :exception, except: :saml
  skip_before_action :verify_authenticity_token, only: [:alma, :saml]

  def alma
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(request.env["omniauth.auth"])
    set_flash_message(:success, :success, kind: "Alma") if is_navigational_format?
    sign_in_and_redirect @user, event: :authentication #this will throw if @user is not activated
  end

  def shibboleth
    @user = User.from_omniauth(request.env["omniauth.auth"])
    sign_in(:user, @user)
    session[:alma_auth_type] = "sso"
    session[:alma_sso_user] = @user.uid
    session[:alma_sso_token] = SecureRandom.hex(10)
    set_flash_message(:success, :success, kind: "Temple Single Sign On") if is_navigational_format?
    redirect_to params[:target] || helpers.users_account_path
  end

  def saml
    auth = request.env["omniauth.auth"]
    auth.uid = auth.extra.raw_info["urn:oid:2.16.840.1.113730.3.1.3"]
    @user = User.from_omniauth(auth)
    sign_in(:user, @user)

    session[:alma_auth_type] = "sso"
    session[:alma_sso_user] = @user.uid
    session[:alma_sso_token] = SecureRandom.hex(10)
    set_flash_message(:success, :success, kind: "Temple Single Sign On") if is_navigational_format?
    redirect_to params[:target] || helpers.users_account_path
  end

  def failure
    redirect_to root_path
  end
end
