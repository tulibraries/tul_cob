# frozen_string_literal: true

require "rails_helper"

RSpec.describe BentoSearch, type: :search_engine do
  let(:search_engine)  { BentoSearch.get_engine("blacklight") }

  let(:search_results) { VCR.use_cassette("bento_search_blacklight") { search_engine.search("james") } }

  let(:expected_fields) { RSpec.configuration.bento_expected_fields }

  describe "Bento Blacklight Search Engine" do
    let (:item) { search_results[0] }

    it "has all the expected fields" do
      expected_fields.each do |field|
        expect(item.send field).not_to be_nil, "expect #{field} to be set."
      end
    end

    it "uses TulStandardDecorator" do
      expect(item.decorator).to eq("TulDecorator")
    end
  end

  describe "#proc_availability_facet_only" do
    let(:controller) { CatalogController.new }
    let(:builder) { SearchBuilder.new(controller) }

    it "does not affect builder.proccessor_chain automatically" do
      expect(builder.processor_chain).to_not include(:availability_facet_only)
    end

    it "Overrides the builder processor_chain" do
      _builder = search_engine.proc_availability_facet_only[builder]
      expect(_builder.processor_chain.last).to eq(:availability_facet_only)
    end
  end
end
