# frozen_string_literal: true

require "rails_helper"

RSpec.describe BentoSearch, type: :search_engine do
  blacklight_se = BentoSearch.get_engine("blacklight")

  blacklight_search_results = VCR.use_cassette("bento_search_blacklight") do
    blacklight_se.search("james")
  end


  let(:expected_fields) { RSpec.configuration.bento_expected_fields }

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

  describe "#proc_remove_facets" do
    let(:builder) { SearchBuilder.new(CatalogController.new) }

    it "does not affect builder.proccessor_chain automatically" do
      expect(builder.processor_chain).to_not include(:format_facet_only)
    end

    it "Overrides the builder processor_chain" do
      _builder = blacklight_se.proc_remove_facets[builder]
      expect(_builder.processor_chain.last).to eq(:remove_facets)
    end
  end
end
