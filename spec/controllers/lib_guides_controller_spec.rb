# frozen_string_literal: true

require "rails_helper"

RSpec.describe LibGuidesController do
  describe "routes" do
    it "is available at /lib_guides" do
      request = { get: "/lib_guides" }
      expect(request).to route_to(controller: "lib_guides", action: "index")
    end
  end

  describe "index" do
    it "renders the json returned by the LibGuidesApi class" do
      expect(LibGuidesApi).to receive(:fetch).with("query terms").and_return(
        [{ name: "Guide 1", url: "https://example.com/1" }, { name: "Guide 2", url: "https://example.com/2" }]
      )

      get :index, params: { q: "query terms" }

      expect(response).to be_successful
      expect(controller.instance_variable_get(:@guides)).to eq([
        { "name" => "Guide 1", "url" => "https://example.com/1" },
        { "name" => "Guide 2", "url" => "https://example.com/2" }
      ])
    end
  end
end
