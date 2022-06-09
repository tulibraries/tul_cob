# frozen_string_literal: true

require "rails_helper"

RSpec.describe SessionsController, type: :controller do
  before(:each) do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "new session over ajax" do
    it "should set headers not to store" do
      request.headers["X-Requested-With"] = "XMLHttpRequest"
      request.headers["HTTP_ACCEPT"] = "*/*"
      get :new

      expect(response.headers["Cache-Control"]).to eq("no-store")
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
end
