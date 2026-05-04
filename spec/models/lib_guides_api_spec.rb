# frozen_string_literal: true

require "rails_helper"

RSpec.describe LibGuidesApi do
  subject(:api) { described_class.new("Search Term") }

  context "when the API responds successfully" do
    it "returns data from the API response as json" do
      allow(HTTParty).to receive(:get).and_return(
        double(success?: true, body: [{ name: "Guide Name", url: "https://example.com/1" }].to_json))
      expect(api.as_json).to eq([{ "name" => "Guide Name", "url" => "https://example.com/1" }])
    end

    it "limits the number of results returned to 3" do
      json = Array.new(4) do |i|
        { name: "Guide Name #{i}", url: "https://example.com/#{i}" }
      end.to_json
      allow(HTTParty).to receive(:get).and_return(double(success?: true, body: json))
      expect(api.as_json.length).to be 3
    end

    context "when there are many results" do
      it "sorts Subject, Topic, and General Purpose first, then Course, then by original order" do
        allow(HTTParty).to receive(:get).and_return(
          double(success?: true, body: [
            { id: 1, "type_label" => "Subject Guide" },
            { id: 2, "type_label" => "General Purpose Guide" },
            { id: 3, "type_label" => "Course Guide" },
            { id: 4, "type_label" => "Topic Guide" },
            { id: 5, "type_label" => "Subject Guide" },
          ].to_json))
        expect(api.as_json.map { |o| o["id"] }).to eq([1, 2, 4])
      end
    end

    context "when there are no results" do
      it "returns an empty array" do
        allow(HTTParty).to receive(:get).and_return(
          double(success?: true, body: [].to_json))
        expect(api.as_json.map { |o| o["id"] }).to eq([])
      end
    end

    it "builds the request URL from configured base_url with path" do
      allow(api).to receive(:config).and_return(
        {
          "base_url" => "https://example.libapps.com/1.1/guides",
          "api_key" => "abc123",
          "site_id" => "17",
          "query" => { "sort_by" => "relevance", "expand" => "owner", "guide_types" => "1,2,3,4", "status" => 1 }
        }
      )
      allow(HTTParty).to receive(:get).and_return(
        double(success?: true, body: [].to_json)
      )

      api.as_json

      expect(HTTParty).to have_received(:get).with(a_string_starting_with("https://example.libapps.com/1.1/guides?"))
    end

    it "uses the configured base_url as-is when host-only is provided" do
      allow(api).to receive(:config).and_return(
        {
          "base_url" => "https://example.libapps.com",
          "api_key" => "abc123",
          "site_id" => "17",
          "query" => { "sort_by" => "relevance", "expand" => "owner", "guide_types" => "1,2,3,4", "status" => 1 }
        }
      )
      allow(HTTParty).to receive(:get).and_return(
        double(success?: true, body: [].to_json)
      )

      api.as_json

      expect(HTTParty).to have_received(:get).with(a_string_starting_with("https://example.libapps.com?"))
    end
  end

  context "when the API fails to respond successfully" do
    before do
      allow(HTTParty).to receive(:get).and_return(
        double(success?: false, body: "<html>")
      )
    end

    it "handles the response and returns an empty array" do
      expect(api.as_json).to eq([])
    end
  end

  context "when the API claims to return successfully but has malformed JSON" do
    before do
      allow(HTTParty).to receive(:get).and_return(
        double(success?: true, body: "<html>")
      )
    end

    it "handles the response and returns an empty array" do
      expect(api.as_json).to eq([])
    end
  end
end
