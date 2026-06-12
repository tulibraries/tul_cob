# frozen_string_literal: true

require "rails_helper"

RSpec.describe SessionsController, type: :controller do
  let(:password) { "password123" }
  let(:user) { User.create!(email: "community@example.com", password:, password_confirmation: password) }

  before(:each) do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "new session over ajax" do
    it "should set headers not to store" do
      request.headers["X-Requested-With"] = "XMLHttpRequest"
      request.headers["HTTP_ACCEPT"] = "*/*"
      get :new

      expect(response.headers["Cache-Control"]).to eq("private, no-store")
      expect(response.headers["Pragma"]).to eq("no-cache")
      expect(response.headers["Expires"]).to eq("Fri, 01 Jan 1990 00:00:00 GMT")
    end
  end

  describe "new session not over ajax" do
    it "should generate a @document.class SolrDocument" do
      get :new
      expect(controller.instance_variable_get("@document").class).to eq(SolrDocument)
    end
  end

  describe "before_action get_manifold_alerts" do
    context ":new action" do
      it "sets @manifold_alerts_thread" do
        get :new
        expect(controller.instance_variable_get("@manifold_alerts_thread")).to be_kind_of(Thread)
      end
    end
  end

  describe "POST create" do
    it "sets the login cookie" do
      post :create, params: { user: { email: user.email, password: } }

      expect(cookies.signed[LoginCookie::LOGIN_COOKIE_NAME]).to include("user_id" => user.id)
    end

    it "redirects to redirect_to when provided" do
      post :create, params: { user: { email: user.email, password: }, redirect_to: "/catalog/123" }

      expect(response).to redirect_to("/catalog/123")
    end
  end

  describe "DELETE destroy" do
    it "removes the login cookie" do
      sign_in user, scope: :user
      cookies.signed[LoginCookie::LOGIN_COOKIE_NAME] = { user_id: user.id }

      delete :destroy

      expect(response.headers["Set-Cookie"]).to match(/#{LoginCookie::LOGIN_COOKIE_NAME}=;/)
    end
  end

  describe "GET social_login_callback" do
    let(:auth_secret) { "secret" }
    let(:token) do
      JWT.encode(
        {
          "id" => "social-user",
          "provider" => "alma",
          "email" => "social@example.com",
          "name" => "Social User"
        },
        auth_secret,
        "HS256"
      )
    end

    before do
      allow(Rails.configuration).to receive(:apis).and_return(alma: { auth_secret: })
    end

    it "sets the login cookie" do
      get :social_login_callback, params: { jwt: token }

      user = User.find_by(provider: "alma", uid: "social-user")
      expect(cookies.signed[LoginCookie::LOGIN_COOKIE_NAME]).to include("user_id" => user.id)
    end
  end
end
