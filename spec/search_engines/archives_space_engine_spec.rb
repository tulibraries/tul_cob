# frozen_string_literal: true

require "rails_helper"

RSpec.describe BentoSearch::ArchivesSpaceEngine, type: :engine do
  subject(:engine) { described_class.new }

  describe "#search_implementation" do
    it "returns a BentoSearch::Results object" do
      results = engine.search_implementation(query: "Temple University")
      expect(results).to be_a(BentoSearch::Results)
    end
  end

  describe "#conform_to_bento_result" do
    let(:sample_item) do
      {
        "title" => "Sample Record",
        "uri" => "/repositories/4/resources/150"
      }
    end

    it "returns a BentoSearch::ResultItem" do
      result = engine.conform_to_bento_result(sample_item)
      expect(result).to be_a(BentoSearch::ResultItem)
    end

    it "includes a title and link" do
      result = engine.conform_to_bento_result(sample_item)
      expect(result.title).to include("Sample Record")
      expect(result.link).to match(%r{https://scrcarchivesspace\.temple\.edu/})
    end
  end
end
