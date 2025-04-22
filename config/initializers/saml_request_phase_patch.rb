# frozen_string_literal: true

require "omniauth/strategies/saml"

module OmniAuth
  module Strategies
    class SAML

      def request_phase
        auth_request = OneLogin::RubySaml::Authrequest.new
        with_settings do |settings|
          params = auth_request.create_params(settings)
          form_html = <<-HTML
            <html>
            <body onload="document.forms[0].submit()">
              <form method="POST" action="#{settings.idp_sso_service_url}">
                <input type="hidden" name="SAMLRequest" value="#{params[:SamlRequest]}" />
                <input type="hidden" name="RelayState" value="#{params[:RelayState]}" />
              </form>
            </body>
            </html>
          HTML
          Rack::Response.new(form_html, 200, { 'Content-Type' => 'text/html' }).finish
        end
      end

    end
  end
end

