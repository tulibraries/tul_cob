# frozen_string_literal: true

require "rails_helper"


RSpec.describe Blacklight::PrimoCentral::Repository , type: :model do
  let(:config) { PrimoCentralController.blacklight_config }
  let(:repo) { Blacklight::PrimoCentral::Repository.new(config) }

  subject { repo }

  describe ".search" do
    context "skip_search? true" do
      it "returns empty response" do
        expect(subject.search(skip_search?: true)).to eq(
          {
            "response" => { "numFound" => 0, "start" => 0, "docs" => [] },
            "facets" => [],
            "stats" => { "stats_fields" => {} } }
        )
      end
    end

    context "with a date range" do
      let(:range) { Struct.new(:min, :max).new(2024, nil) }
      let(:primo_response) do
        {
          "info" => { "total" => 1 },
          "docs" => [],
          "facets" => [
            {
              "name" => "creationdate",
              "values" => [
                { "value" => "2023", "count" => "1" },
                { "value" => "2024", "count" => "1" },
                { "value" => "2026", "count" => "1" }
              ]
            }
          ]
        }
      end

      before do
        allow(Rails.cache).to receive(:fetch) { |&block| block.call }
        allow(Primo).to receive(:find).and_return(primo_response)
      end

      it "uses the requested range for response stats" do
        response = subject.search(params: { query: { q: "test" }, range: range })

        expect(response.dig("stats", "stats_fields", "creationdate", "min")).to eq(2024)
      end
    end
  end
end
