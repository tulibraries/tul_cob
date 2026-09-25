# frozen_string_literal: true

require "rails_helper"

RSpec.describe BentoSearch::LibGuidesEngine do
  subject(:engine) { described_class.new }

  describe "#search_implementation" do
    let(:api_config) do
      {
        base_url: "https://guides.example.test/api/guides",
        site_id: 42,
        "client_id" => "client-id",
        "client_secret" => "client-secret",
        query: {
          status: 2,
          sort_by: "title",
          expand: "subjects",
          guide_types: "5"
        }
      }
    end
    let(:guides) do
      [
        {
          "name" => "Guide One",
          "description" => "Description one",
          "url" => "https://guides.example.test/one"
        },
        {
          "name" => "Guide Two",
          "description" => "",
          "url" => "https://guides.example.test/two"
        },
        {
          "name" => "Guide Three",
          "description" => nil,
          "url" => "https://guides.example.test/three"
        },
        {
          "name" => "Guide Four",
          "description" => "Description four",
          "url" => "https://guides.example.test/four"
        }
      ]
    end

    before do
      allow(Rails.configuration).to receive(:apis).and_return({ lib_guides: api_config })
    end

    it "authenticates, searches, and converts the first three guides" do
      token_response = double("TokenResponse", body: { access_token: "TOKEN" }.to_json)
      guides_response = double("GuidesResponse", success?: true, body: guides.to_json)
      expected_query = {
        site_id: 42,
        search_terms: "civil+rights",
        status: 2,
        sort_by: "title",
        expand: "subjects",
        guide_types: "5"
      }.to_param

      expect(HTTParty).to receive(:post).with(
        "https://lgapi-us.libapps.com/1.2/oauth/token",
        {
          body: {
            client_id: "client-id",
            client_secret: "client-secret",
            grant_type: "client_credentials"
          }
        }
      ).and_return(token_response)
      expect(HTTParty).to receive(:get).with(
        "https://guides.example.test/api/guides?#{expected_query}",
        { headers: { "Authorization" => "Bearer TOKEN" } }
      ).and_return(guides_response)

      results = engine.search_implementation(query: "civil rights")

      expect(results.length).to eq(3)
      expect(results.map(&:title)).to eq(["Guide One", "Guide Two", "Guide Three"])
      expect(results[0].abstract).to eq("Description one")
      expect(results[1].abstract).to be_nil
      expect(results[2].abstract).to be_nil
      expect(results.map(&:link)).to eq([
        "https://guides.example.test/one",
        "https://guides.example.test/two",
        "https://guides.example.test/three"
      ])
    end

    it "uses default configuration and returns no results for an unsuccessful response" do
      allow(Rails.configuration).to receive(:apis).and_return({})
      token_response = double("TokenResponse", body: { access_token: "TOKEN" }.to_json)
      guides_response = double("GuidesResponse", success?: false, body: "Unavailable")
      expected_query = {
        site_id: 17,
        search_terms: "history",
        status: 1,
        sort_by: "relevance",
        expand: "owner",
        guide_types: "1,2,3,4"
      }.to_param

      expect(HTTParty).to receive(:post).with(
        "https://lgapi-us.libapps.com/1.2/oauth/token",
        {
          body: {
            client_id: nil,
            client_secret: nil,
            grant_type: "client_credentials"
          }
        }
      ).and_return(token_response)
      expect(HTTParty).to receive(:get).with(
        "https://lgapi-us.libapps.com/1.2/guides?#{expected_query}",
        { headers: { "Authorization" => "Bearer TOKEN" } }
      ).and_return(guides_response)

      expect(engine.search_implementation(query: "history")).to be_empty
    end
  end

  describe "#url" do
    it "builds the LibGuides search URL with only the query" do
      helper = double("ViewHelper", params: { q: "education", page: "2" })

      expect(engine.url(helper)).to eq("https://guides.temple.edu/srch.php?q=education")
    end
  end

  describe "#view_link" do
    it "renders a link to all LibGuides results" do
      helper = double("ViewHelper")
      expected_url = "https://guides.temple.edu/srch.php?q=education"

      expect(engine).to receive(:url).with(helper).and_return(expected_url)
      expect(helper).to receive(:link_to)
        .with("See all results", expected_url, class: "bento-full-results bento_lib_guides_header")
        .and_return("<a>See all results</a>")

      expect(engine.view_link(12, helper)).to eq("<a>See all results</a>")
    end
  end
end
