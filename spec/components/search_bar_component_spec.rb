# frozen_string_literal: true

require "rails_helper"

RSpec.describe Blacklight::SearchBarComponent, type: :component do
  describe "#advanced_search_url" do
    it "preserves clauses, operators, and ranges on the supplied advanced search route" do
      params = {
        "search_field" => "advanced",
        "clause" => {
          "0" => { "field" => "title", "query" => "united", "match" => "contains" },
          "1" => { "field" => "title", "query" => "states", "op" => "should", "match" => "begins_with" }
        },
        "range" => { "lc_classification" => { "begin" => "A", "end" => "Z" } },
        "page" => "2"
      }
      component = described_class.new(url: "/journals", params: params, advanced_search_url: "/journals/advanced")

      uri = URI.parse(component.advanced_search_url)

      expect(uri.path).to eq("/journals/advanced")
      expect(Rack::Utils.parse_nested_query(uri.query)).to eq(params.except("page"))
      expect(params["page"]).to eq("2")
    end

    it "preserves a simple query for the first advanced search row" do
      component = described_class.new(
        url: "/catalog",
        params: { q: "sarbanes", search_field: "title" },
        advanced_search_url: "/catalog/advanced"
      )

      expect(Rack::Utils.parse_nested_query(URI.parse(component.advanced_search_url).query)).to eq(
        "q" => "sarbanes", "search_field" => "title"
      )
    end
  end
end
