# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include LoginCookie

  protect_from_forgery with: :exception, except: :saml
  skip_before_action :verify_authenticity_token, only: [:alma, :saml]
  after_action :set_login_cookie, only: [:alma, :saml], if: :user_signed_in?

  def alma
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(request.env["omniauth.auth"])
    set_flash_message(:success, :success, kind: "Alma") if is_navigational_format?
    sign_in_and_redirect @user, event: :authentication #this will throw if @user is not activated
  end

  def saml
    auth = request.env["omniauth.auth"]
    omniauth_params = request.env["omniauth.params"]

    auth.uid = auth.extra.raw_info["urn:oid:2.16.840.1.113730.3.1.3"]
    @user = User.from_omniauth(auth)
    sign_in(:user, @user, event: :authentication)

    session[:alma_auth_type] = "sso"
    session[:alma_sso_user] = @user.uid
    session[:alma_sso_token] = SecureRandom.hex(10)
    set_flash_message(:success, :success, kind: "Temple Single Sign On") if is_navigational_format?
    redirect_to (omniauth_params["target"] || helpers.users_account_path), allow_other_host: true
  end

  def failure
    redirect_to root_path
  end
end
