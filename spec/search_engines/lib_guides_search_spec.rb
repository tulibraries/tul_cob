# frozen_string_literal: true

require "rails_helper"

RSpec.describe "lib guides search engine", type: :search_engine do

  let(:search_results) { BentoSearch.get_engine("lib_guides").search("education") }
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
