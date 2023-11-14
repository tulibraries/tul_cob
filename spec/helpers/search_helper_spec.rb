# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchHelper, type: :helper do
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
