# frozen_string_literal: true

require "rails_helper"

RSpec.describe "cdm search engine", type: :search_engine do

  let(:query) { "art history" }
  let(:theses_query) { "theses and dissertations" }
  let(:awards_query) { "Undergraduate Research Prize Winners" }
  let(:search_engine)  { BentoSearch.get_engine("cdm") }
  let(:search_results) { VCR.use_cassette("bento_search_cdm") { search_engine.search(query) } }
  let(:expected_fields) { RSpec.configuration.cdm_expected_fields }

  let(:item) { search_results[0] }

  context "cdm engine" do
    it "has all the expected fields" do
      expected_fields.each do |field|
        expect(item.send field).not_to be_nil, "expect #{field.inspect} to be set."
      end
    end

    it "uses TulStandardDecorator" do
      expect(item.decorator).to eq("TulDecorator")
    end
  end

  context "gets three displayable results" do
    it "includes only records with displayable images" do
      search_results.each do |result|
        stub_request(:get, result.other_links[0]).to_return(status: 200)
      end
    end

    it "returns only results with non-number titles" do
      search_results.each do |result|
        expect(result.title.to_f).to eq(0)
      end
    end

    it "returns three valid results" do
      expect(search_results.size).to be <= 3
    end
  end

  context "when an error gets thrown while processing CDM" do
    let(:query) { "query/" }

    it "defaults to 0 finds" do
      allow(CDM).to receive(:find).with("query%20") { raise StandardError.new("Boo!") }
      allow(Honeybadger).to receive(:notify).with("Ran into error while try to process CDM: Boo!")
    end
  end

  describe "#cdm_collection_name" do
    let(:collections_response) do
      [
        { "alias" => "/p245801coll12", "name" => "Temple University Yearbooks" }
      ]
    end

    it "returns the collection name when the alias with leading slash matches the id" do
      expect(search_engine.send(:cdm_collection_name, "p245801coll12", collections_response))
        .to eq("Temple University Yearbooks")
    end

    it "returns nil when no alias matches the id" do
      expect(search_engine.send(:cdm_collection_name, "nonexistent", collections_response))
        .to be_nil
    end
  end
end
