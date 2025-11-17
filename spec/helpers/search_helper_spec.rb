# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchHelper, type: :helper do
  describe "#bento_link_to_full_results" do
    it "delegates to the engine view_link with a formatted total" do
      results = instance_double("BentoResults",
        engine_id: "cdm",
        total_items: { query_total: 1234 })
      engine = instance_double("CDMEngine")
      formatted_total = helper.number_with_delimiter(1234)

      expect(BentoSearch).to receive(:get_engine).with("cdm").and_return(engine)
      expect(engine).to receive(:view_link).with(formatted_total, helper).and_return("<a>See all results</a>")

      expect(helper.bento_link_to_full_results(results)).to eq("<a>See all results</a>")
    end

    it "returns nil when there are zero results" do
      results = instance_double("BentoResults",
        engine_id: "cdm",
        total_items: { query_total: 0 })

      expect(BentoSearch).not_to receive(:get_engine)

      expect(helper.bento_link_to_full_results(results)).to be_nil
    end
  end

  describe "#path_for_books_and_media_facet(facet_field, item)" do
    context "search query is empty" do
      let(:item) {  OpenStruct.new(value: "digital_collections") }
      let(:facet_field) { "" }
      let(:params) { { "q": "" } }
      expected_url = "https://digital.library.temple.edu/digital/search"

      it "has links to search page" do
        expect(path_for_books_and_media_facet(facet_field, item)).to eq(expected_url)
      end
    end

    context "search term is used" do
      let(:item) {  OpenStruct.new(value: "digital_collections") }
      let(:facet_field) { "" }
      let(:params) { { "q": "japan" } }

      it "has link to order/nosort" do
        expected_url = "https://digital.library.temple.edu/digital/search/searchterm/#{params[:q]}/order/nosort"

        expect(path_for_books_and_media_facet(facet_field, item)).to eq(expected_url)
      end
    end

    context "search term has a forward slash in it"  do
      let(:item) {  OpenStruct.new(value: "digital_collections") }
      let(:facet_field) { "" }
      let(:params) { { "q": "japan/" } }

      it "removes forward slash form query" do
        expected_url = "https://digital.library.temple.edu/digital/search/searchterm/japan /order/nosort"

        expect(path_for_books_and_media_facet(facet_field, item)).to eq(expected_url)
      end
    end
  end
end
