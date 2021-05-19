# frozen_string_literal: true

module UsersHelper
  require "date"

  def expiry_date(hold)
    begin
      make_date(DateTime.parse(hold.expiry_date).to_s) if hold.respond_to? :expiry_date
    rescue => exception
      Honeybadger.notify("On Hold Expiry Date error: #{exception.message}") unless hold.expiry_date.blank?
      "N/A"
    end
  end

  def make_date(date)
    DateTime.iso8601(date).in_time_zone.strftime("%m/%d/%Y")
  end

  def loan_options(loan)
    options = { class: "form-check-input" }
    options[:disabled] = true unless loan.renewable?
    options
  end

  def new_user_session_with_redirect_path(redirect = request.url)
    new_user_session_path(redirect_to: redirect)
  end

  def alma_social_login_url(backUrl: nil, redirect_to: nil)
    if backUrl.nil?
      # alma_social_login_callback_url should be either manually
      # defined in a helper or auto-defined by a route
      if respond_to? :alma_social_login_callback_url
        backUrl = alma_social_login_callback_url
      else
        raise "alma_social_login_callback_url helper method not found"
      end
    end

    if redirect_to
      parsed_backUrl = URI.parse(backUrl)
      new_query = URI.decode_www_form(parsed_backUrl.query || "") << ["redirect_to", "#{redirect_to}"]
      parsed_backUrl.query = URI.encode_www_form(new_query)
      backUrl = parsed_backUrl.to_s
    end

    query = {
        institutionCode: alma_institution_code,
        backUrl: backUrl
    }
    URI::HTTPS.build(
      host: alma_domain,
      path: "/view/socialLogin",
      query: query.to_query).to_s
  end

  # TODO: Remove once we go completely to k8.
  def student_faculty_login_uri
    if Rails.configuration.devise["saml_certificate"].present?
      omniauth_authorize_path(resource_name, :saml, target: params[:redirect_to])
    else
      omniauth_authorize_path(resource_name, :shibboleth, target: params[:redirect_to])
    end
  end
end
