# frozen_string_literal: true

require "rails_helper"

RSpec.describe BentoSearch, type: :search_engine do
  primo_se = BentoSearch.get_engine("articles")

  primo_search_results = VCR.use_cassette("bento_search_primo") do
    primo_se.search("james")
  end

  let(:expected_fields) { RSpec.configuration.bento_expected_fields }

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
