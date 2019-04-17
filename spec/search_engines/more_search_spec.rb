# frozen_string_literal: true

require "rails_helper"

RSpec.describe BentoSearch, type: :search_engine do

  let(:search_engine)  { BentoSearch.get_engine("books_and_media") }

  let(:search_results) { VCR.use_cassette("bento_search_more") { search_engine.search("food") } }

  let(:expected_fields) { RSpec.configuration.bento_expected_fields }

  describe "Bento Books and Media Search Engine" do
    let (:item) { search_results[0] }

    it "sets custom_data to a Blackligh::Solr::Response" do
      expect(item.custom_data).to be_a(Blacklight::Solr::Response)
    end
  end

  describe "Assumptions we make about Blacklight::Solr::Response" do
    let (:response) { Blacklight::Solr::Response.new(nil, nil) }

    it "has a face_fields attribute" do
      expect(response.facet_fields["format"]).to be_nil
    end

    it "has a facet_counts attribute" do
      expect(response.facet_counts["facet_fields"]).to be_nil
    end
  end

  describe "#proc_minus_books_journals" do
    let(:controller) { CatalogController.new }
    let(:builder) { SearchBuilder.new(controller) }

    it "does not affect builder.proccessor_chain automatically" do
      expect(builder.processor_chain).not_to include(:no_journals)
    end

    it "Appends :no_journals processor to processor_chain" do
      _builder = search_engine.proc_minus_books_journals[builder]
      expect(_builder.processor_chain).to include(:no_journals)
    end
  end

end
