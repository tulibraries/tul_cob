# frozen_string_literal: true

require "rails_helper"

RSpec.describe SessionsController, type: :controller do
  before(:each) do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "new session over ajax" do
    it "should set headers not to cache" do
      request.headers["X-Requested-With"] = "XMLHttpRequest"
      request.headers["HTTP_ACCEPT"] = "*/*"
      get :new

      expect(response.headers["Cache-Control"]).to eq("no-cache, no-store")
      expect(response.headers["Pragma"]).to eq("no-cache")
      expect(response.headers["Expires"]).to eq("Fri, 01 Jan 1990 00:00:00 GMT")
    end
  end

  describe "new session not over ajax" do
    it "should not set no-cache headers" do
      get :new
      expect(response.headers["Pragma"]).to be_nil
    end
  end
end
