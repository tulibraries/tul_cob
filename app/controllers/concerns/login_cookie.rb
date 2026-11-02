# frozen_string_literal: true

module LoginCookie
  extend ActiveSupport::Concern

  LOGIN_COOKIE_NAME = "logged_in"
  LOGIN_COOKIE_VALUE = ENV.fetch("LOGIN_COOKIE_VALUE", "logged_in").freeze

  private

    def set_login_cookie(user = current_user)
      return if user.blank?

      cookies[LOGIN_COOKIE_NAME] = {
        value: LOGIN_COOKIE_VALUE,
        path: "/",
        httponly: true,
        same_site: :lax,
        secure: Rails.env.production?
      }
    end

    def clear_login_cookie
      cookies[LOGIN_COOKIE_NAME] = {
        value: "",
        path: "/",
        expires: 1.year.ago,
        httponly: true,
        same_site: :lax,
        secure: Rails.env.production?
      }
    end

    def clear_stale_login_cookie
      return if user_signed_in?
      return if cookies[LOGIN_COOKIE_NAME].blank?

      clear_login_cookie
    end
end
