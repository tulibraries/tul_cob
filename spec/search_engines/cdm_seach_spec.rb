# frozen_string_literal: true

require "rails_helper"

RSpec.describe "cdm search engine", type: :search_engine do

  let(:query) { "foo" }
  let(:search_results) { BentoSearch.get_engine("cdm").search(query) }
  let(:content_dm_results) { { "results" => { "pager" => { "total" => "415" } } } }

  before do
    stub_request(:get, /contentdm/)
      .to_return(status: 200,
    headers: { "Content-Type" => "application/json" },
    body: JSON.dump(content_dm_results))
  end

  it "sets the total found items" do
    expect(search_results.total_items).to eq("415")
  end

  context "non ASCII query" do
    let(:query) { "Read Myron H. Dembo. 2004. Motivation and Learning Strategies for College Success: A Self-Management Approach, Chapter 1, “Academic Self-Management,” 3-17." }

    it "handles non asci queries" do
      expect(search_results.total_items).to eq("415")
    end
  end
end
