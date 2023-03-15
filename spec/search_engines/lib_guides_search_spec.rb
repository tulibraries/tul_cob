# frozen_string_literal: true

require "rails_helper"

RSpec.describe "lib guides search engine", type: :search_engine do
  let(:search_engine)  { BentoSearch.get_engine("lib_guides") }
  let(:search_results) { VCR.use_cassette("bento_search_lib_guides") { search_engine.search("education") } }
  let(:expected_fields) { RSpec.configuration.web_expected_fields }

  describe "Bento Lib Guides Search Engine" do
    let (:item) { search_results[0] }

    it "has all the expected fields" do
      expected_fields.each do |field|
        expect(item.send field).not_to be_nil, "expect #{field.inspect} to be set."
      end
    end

    it "uses TulStandardDecorator" do
      expect(item.decorator).to eq("TulDecorator")
    end
  end
end
