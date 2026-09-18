# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Basic search after advanced search" do
  let(:response_body) { default_articles_response_body }

  before do
    stub_request(:get, /primo/)
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: response_body
      )
  end

  scenario "plain search does not carry advanced params forward" do
    visit "/articles/advanced"
    fill_in "q_1", with: "foo"
    fill_in "q_2", with: "bar"
    click_button "advanced-search-submit"

    expect(current_url).to match(/q_1=foo/)

    fill_in "q", with: "cat"
    click_button "search"

    expect(current_url).to match(/q=cat/)
    expect(current_url).not_to match(/q_1=foo/)
    expect(current_url).not_to match(/q_2=bar/)
    expect(current_url).not_to match(/clause/)
  end

  scenario "catalog plain search does not carry advanced params forward" do
    visit "/catalog?#{ {
      clause: {
        0 => { field: "all_fields", query: "test", match: "contains" }
      },
      range: { lc_classification: { begin: "A", end: "Z" } },
      search_field: "advanced",
    }.to_query}"

    fill_in "q", with: "cat"
    click_button "search"

    expect(current_url).to match(/q=cat/)
    expect(current_url).not_to match(/q_1=test/)
    expect(current_url).not_to match(/f_1=all_fields/)
    expect(current_url).not_to match(/operator/)
    expect(current_url).not_to match(/op_1=AND/)
    expect(current_url).not_to match(/search_field=advanced/)
  end

  def default_articles_response_body
    File.read("spec/fixtures/articles_search_response.json")
  end
end
