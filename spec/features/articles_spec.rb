# frozen_string_literal: true

require "rails_helper"
require "yaml"
include ApplicationHelper

RSpec.feature "Articles Search" do

  let(:response_body) { default_articles_response_body }

  before(:each) do
    stub_request(:get, /primo/).
      to_return(status: 200,
                headers: { "Content-Type" => "application/json" },
                body: response_body)
  end

  scenario "Search" do
    visit "/articles"
    fill_in "q", with: "foo"
    click_button "search"
    expect(current_url).to eq "http://www.example.com/articles?search_field=any&q=foo"
    expect(page).to have_css("#facets")
    within("article.document-position-1 h3") do
      expect(page).to have_text("Otter")
    end
    within first(".document-metadata") do
      expect(page).to have_text "Is Part Of:"
      expect(page).to have_text "Author/Creator"
      has_css?(".avail-button", visible: true)
    end
  end

  scenario "advanced search followed by plain search" do
    visit "/articles/advanced"
    expect(page).to have_select("Article Search Settings")
    expect(page).to have_select("Resource Type")
    expect(page).to have_select("Language")
    expect(page).to have_field("range[creationdate][begin]")
    expect(page).to have_field("range[creationdate][end]")
    fill_in "q_1", with: "foo"
    fill_in "q_2", with: "bar"
    click_button "advanced-search-submit"
    expect(current_url).to match /q_1=foo/
    expect(current_url).to match /q_2=bar/
    fill_in "q", with: "cat"
    click_button "search"
    expect(current_url).to match /q=cat/
    expect(current_url).not_to match /q_1=foo/
    expect(current_url).not_to match /q_2=bar/
  end

  scenario "visit advanced articles results page" do
    visit "/articles?#{ {
      clause: {
        0 => { field: "all_fields", query: "music", match: "contains" },
        1 => { field: "all_fields", query: "foo", match: "contains", op: "must" }
      },
      search_field: "advanced",
    }.to_query}"

    expect(page).to have_http_status(:success)
  end

  def default_articles_response_body
    File.open("spec/fixtures/articles_search_response.json", "r") do |file|
      file.read
    end
  end
end
