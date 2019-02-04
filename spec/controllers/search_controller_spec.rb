# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchController, type: :controller do

  describe "#split_and_merge" do
    let(:results) { BentoSearch::ConcurrentSearcher.new(:more, :cdm).search("foo").results }
    let(:subject) { controller.send(:split_and_merge, results) }

    before {
      stub_request(:get, /contentdm/)
        .to_return(status: 200,
                  headers: { "Content-Type" => "application/json" },
                  body: JSON.dump(content_dm_results))
    }

    context "content dm and regular results are present" do

      it "merges content-dm totals with resource types format facets" do
        facets = subject["resource_types"].first.custom_data.facet_fields
        expect(facets).to eq("format" => [ "cdm", "415" ])
      end

    end
  end

  def content_dm_results
    { "results" => { "pager" => { "total" => "415" } } }
  end
end
