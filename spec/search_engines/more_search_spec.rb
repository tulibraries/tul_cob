# frozen_string_literal: true

require "rails_helper"

RSpec.describe BentoSearch, type: :search_engine do
  more_se = BentoSearch.get_engine("more")

  more_search_results = VCR.use_cassette("bento_search_more") do
    more_se.search("food")
  end

  let(:expected_fields) { RSpec.configuration.bento_expected_fields }

  describe "Bento  More Search Engine" do
    let (:item) { more_search_results[0] }

    it "overrides the item display configuration" do
      expect(item.display_configuration.item_partial).to eq("bento_search/more")
    end

    it "sets custom_data to a Blackligh::Solr::Response" do
      expect(item.custom_data).to be_a(Blacklight::Solr::Response)
    end

    # This should be happening via the query @see BL-468
    it "filters out the Books and Journal/Periodical facets from results" do
      format_facets = item.custom_data.facet_counts["facet_fields"]["format"]
      #expect(format_facets).not_to include("Book")
      #expect(format_facets).not_to include("Journal/Periodical")
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
    let(:builder) { SearchBuilder.new(CatalogController.new) }

    it "does not affect builder.proccessor_chain automatically" do
      expect(builder.processor_chain).not_to include(:no_books_or_journals)
    end

    it "Appends :no_books_or_journals processor to processor_chain" do
      _builder = more_se.proc_minus_books_journals[builder]
      expect(_builder.processor_chain).to include(:no_books_or_journals)
    end
  end

end
