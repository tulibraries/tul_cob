# frozen_string_literal: true

require "jwt"

module BlacklightAlma
  # module to be mixed in to a Devise::SessionController
  #
  # See https://developers.exlibrisgroup.com/blog/Leveraging-Social-Login-with-Alma
  #
  module SocialLogin
    extend ActiveSupport::Concern

    # User is redirected to this action after they've successfully logged in
    # through a social login provider. This performs the devise login.
    def social_login_callback
      decode_result = JWT.decode(params[:jwt], ENV["ALMA_AUTH_SECRET"], true, algorithm: "HS256")
      jwt = decode_result[0]

      # keys in 'jwt' hash: iss, aud, exp, jti, iat, nbf, sub, id, name, email, provider

      user = social_login_user_model.where(provider: jwt["provider"], uid: jwt["id"]).first_or_create do |user|
        user.uid        = jwt["id"]
        user.provider   = jwt["provider"]
        user.email      = jwt["email"]
      end


      sign_in(:user, user)

      social_login_populate_session(jwt)

      redirect_to social_login_callback_redirect
    end

    # populate the session
    def social_login_populate_session(jwt)
      session[:user_name] = jwt["name"]
      session[:alma_id] = jwt["id"]
      session[:alma_auth_type] = "social_login"
      session[:alma_social_login_provider] = jwt["provider"]
    end

    # This gets called on newly created User objects
    # so that they can be filled
    def social_login_fill_new_user(user, jwt)
      # no-op
    end

    # @return [Class] class object to use for users
    def social_login_user_model
      User
    end

    # @return [String] URL to redirect to after login
    def social_login_callback_redirect
      params[:redirect_to] || helpers.users_account_path
    end
  end
end
