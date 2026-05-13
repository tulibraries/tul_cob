# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  describe "SAML Auth" do
    let(:saml_uid) { "tu123456789" }
    let(:target_path) { "/catalog/991032238599703811" }

    before(:each) do
      request.env["devise.mapping"] = Devise.mappings[:user]
      auth = OmniAuth.config.mock_auth[:default]
      auth.extra = OpenStruct.new(raw_info: { "urn:oid:2.16.840.1.113730.3.1.3" => saml_uid })
      request.env["omniauth.auth"] = auth
    end


    context "A target redirect is defined" do
      it "redirects to the target" do
        request.env["omniauth.params"] = { "target" => target_path }
        get :saml
        expect(response.status).to redirect_to(target_path)
      end

      it "sets the login cookie" do
        request.env["omniauth.params"] = { "target" => target_path }
        get :saml
        user = User.find_by(uid: saml_uid)
        expect(cookies.signed[LoginCookie::LOGIN_COOKIE_NAME]).to include("user_id" => user.id)
      end
    end

    context "A target redirect is not defined" do
      it "redirects to account page" do
        request.env["omniauth.params"] = {}
        get :saml
        expect(response.status).to redirect_to("/users/account")
      end
    end

  end

end
