# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookmarksController do
  describe "index" do
    it "does not get cached" do
      get :index

      expect(response.headers["Cache-Control"]).to eq("no-store")
      expect(response.headers["Pragma"]).to eq("no-cache")
      expect(response.headers["Expires"]).to eq("Fri, 01 Jan 1990 00:00:00 GMT")
    end
  end
end
