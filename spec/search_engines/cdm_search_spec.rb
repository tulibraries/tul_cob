# frozen_string_literal: true

require "rails_helper"

RSpec.describe "cdm search engine", type: :search_engine do

  let(:query) { "ymca" }
  let(:theses_query) { "theses and dissertations" }
  let(:awards_query) { "Undergraduate Research Prize Winners" }
  let(:cdm_fields) { "title!date" }
  let(:cdm_format) { "json" }
  let(:search_engine)  { BentoSearch.get_engine("cdm") }
  let(:search_results) { VCR.use_cassette("bento_search_cdm") { search_engine.search(query, cdm_fields: cdm_fields, cdm_format: cdm_format) } }
  let(:theses_results) { VCR.use_cassette("bento_search_cdm_theses") { search_engine.search(theses_query, cdm_fields: cdm_fields, cdm_format: cdm_format) } }
  let(:awards_results) { VCR.use_cassette("bento_search_cdm_awards") { search_engine.search(awards_query, cdm_fields: cdm_fields, cdm_format: cdm_format) } }
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

    it "does not include theses collection" do
      theses_results.each do |result|
        expect(result.source_title).not_to eq("p245801coll10")
      end
    end

    it "does not include awards collection" do
      awards_results.each do |result|
        expect(result.source_title).not_to eq("p15037coll12")
      end
    end
  end

  context "when an error gets thrown while processing CDM" do
    let(:query) { "query/" }

    it "defaults to 0 finds" do
      allow(CDM).to receive(:find).with("query%20") { raise StandardError.new("Boo!") }
      allow(Honeybadger).to receive(:notify).with("Ran into error while try to process CDM: Boo!")
    end
  end
end
