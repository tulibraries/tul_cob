# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  describe "SAML Auth" do
    before(:each) do
      request.env["devise.mapping"] = Devise.mappings[:user]
      auth = OmniAuth.config.mock_auth[:default]
      auth.extra = OpenStruct.new(raw_info: { "urn:oid:2.16.840.1.113730.3.1.3": "foo" })
      request.env["omniauth.auth"] = auth
    end


    context "A target redirect is defined" do
      it "redirects to the target" do
        request.env["omniauth.params"] = { "target" => "foobar" }
        get :saml
        expect(response.status).to redirect_to("foobar")
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
