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
end
