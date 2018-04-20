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

    it "filters out the Books and Journal/Periodical facets from results" do
      format_facets = item.custom_data.facet_counts["facet_fields"]["format"]
      expect(format_facets).not_to include("Book")
      expect(format_facets).not_to include("Journal/Periodical")
    end

  end

end
