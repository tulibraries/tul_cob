# frozen_string_literal: true

require "rails_helper"

RSpec.describe "cdm search engine", type: :search_engine do

  let(:search_results) { BentoSearch.get_engine("cdm").search("foo") }
  let(:content_dm_results) { { "results" => { "pager" => { "total" => "415" } } } }

  it "sets the total found items" do
    stub_request(:get, /contentdm/)
      .to_return(status: 200,
    headers: { "Content-Type" => "application/json" },
    body: JSON.dump(content_dm_results))

    expect(search_results.total_items).to eq("415")
  end
end
