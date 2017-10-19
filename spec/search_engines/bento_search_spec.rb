# frozen_string_literal: true

require "rails_helper"
require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.default_cassette_options = {
    match_requests_on: [:method]
  }
end

RSpec.describe BentoSearch, type: :search_engine do
  primo_se = BentoSearch.get_engine("primo")
  blacklight_se = BentoSearch.get_engine("blacklight")

  primo_search_results = VCR.use_cassette("bento_search_primo") do
    primo_se.search("james")
  end

  blacklight_search_results = VCR.use_cassette("bento_search_blacklight") do
    blacklight_se.search("james")
  end

  let(:expected_fields) { [:title, :authors, :publisher, :link] }

  describe "Bento Blacklight Search Engine" do
    let (:item) { blacklight_search_results[0] }

    it "has all the expected fields" do
      expected_fields.each do |field|
        expect(item.send field).not_to be_nil, "expect #{field} to be set."
      end
    end

    it "uses TulStandardDecorator" do
      expect(item.decorator).to eq("TulDecorator")
    end

  end

  describe "Bento  Primo Search Engine" do
    let (:item) { primo_search_results[0] }
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
