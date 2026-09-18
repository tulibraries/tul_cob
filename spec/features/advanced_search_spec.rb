# frozen_string_literal: true

require "rails_helper"
require "yaml"
include ApplicationHelper

RSpec.feature "Advanced Search" do
  let (:fixtures) {
    YAML.load_file("#{fixture_paths}/features.yml")
  }

  let (:facets) {
    [ "Availability",
      "Library",
      "Resource Type",
      "Language",
      "Publication Year",
      "Library of Congress Classification Range"]}

  describe "page displays facets" do
    scenario "User visits advanced search page" do
      visit "/catalog/advanced"
      within("form.advanced") do
        expect(current_scope).to have_selector("div.advanced-search-facet")
        expect(all("div.advanced-search-facet").size).to eq(facets.size)
        expect(current_scope).not_to have_selector("div.advanced-search-facet", text: "Newly Added")
        all("div.advanced-search-facet").each_with_index do |div_panel, i|
          expect(div_panel).to have_text facets[i]
        end
        all("select.selectize").each do |facet_select|
          expect(facet_select).to have_selector("option", minimum: 1)
        end
      end
    end
  end

  scenario "submits the visible advanced search rows", js: true do
    visit "/catalog/advanced"

    select "Title", from: "f_1"
    select "contains", from: "operator_q_1"
    fill_in "q_1", with: "sarbanes"
    select "Author/creator/contributor", from: "f_2"
    select "contains", from: "operator_q_2"
    fill_in "q_2", with: "oxley"
    choose "op_1_OR"
    fill_in "range_pub_date_sort_begin", with: "2000"
    fill_in "range_pub_date_sort_end", with: "2020"
    select "title (A to Z)", from: "sort"

    expect(page).to have_selector(
      "input[name='clause[0][field]'][value='title']",
      visible: :all
    )
    expect(page).to have_selector(
      "input[name='clause[1][op]'][value='should']",
      visible: :all
    )
    click_button "advanced-search-submit"

    expect(page).to have_selector("h3.index_title", minimum: 1)
  end

  scenario "restores a journals advanced search", js: true do
    visit "/journals/advanced?#{ { q_1: "states", search_field: "advanced" }.to_query }"

    expect(page).to have_field("q_1", with: "states")
  end

  scenario "uses the journals advanced search label" do
    visit "/journals/advanced"

    expect(page).to have_selector("h1", text: "Advanced Journals Search")
    expect(page).to have_title(/Advanced Journals Search/)
  end

  scenario "clears an advanced search" do
    visit "/catalog/advanced?#{ {
      clause: {
        0 => { field: "title", query: "states", match: "contains" }
      },
      search_field: "advanced"
    }.to_query}"

    click_link "Clear Form"

    expect(current_path).to eq("/catalog/advanced")
    expect(find_field("q_1", visible: :all).value).to be_blank
  end

  scenario "restores a populated third row", js: true do
    visit "/catalog/advanced?#{ {
      clause: {
        2 => { field: "title", query: "states", match: "contains" }
      },
      search_field: "advanced"
    }.to_query}"

    expect(page).to have_field("q_3", with: "states")
    expect(page).to have_select("f_3", selected: "Title")
  end

  scenario "restores selected facet filters" do
    visit "/catalog/advanced?#{ { f: { format: ["Book"] } }.to_query }"

    expect(page).to have_selector(
      "select#format option[value='Book'][selected]",
      visible: :all
    )
  end

  describe "Searches" do
    let (:results_selector) { "h3.index_title" }

    scenario "searching title for x AND y" do
      visit advanced_search_path([
        { field: "title", query: "sarbanes", match: "contains" },
        { field: "title", query: "oxley", match: "contains", op: "must" }
      ])

      expect(page).to have_selector(results_selector, minimum: 1)
      expect(page).to have_text("Title sarbanes")
      expect(page).to have_text("Title AND oxley")
      expect(first(results_selector).text.downcase).to include("sarbanes", "oxley")
    end

    scenario "searching title for x OR y" do
      visit advanced_search_path([
        { field: "title", query: "united", match: "contains" },
        { field: "title", query: "states", match: "contains", op: "should" }
      ])
      expect(page).to have_selector(results_selector, minimum: 6)
      expect(page).to have_text("Title united")
      expect(page).to have_text("Title OR states")
    end

    scenario "searching title for x NOT y" do
      visit advanced_search_path([
        { field: "title", query: "united", match: "contains" },
        { field: "title", query: "states", match: "contains", op: "must_not" }
      ])

      expect(page).to have_text("Title united")
      expect(page).to have_text("Title NOT states")
    end

    scenario "searching with begins_with" do
      visit advanced_search_path([
        { field: "title", query: "states", match: "begins_with" }
      ])

      expect(page).to have_selector(results_selector, minimum: 2)
      expect(page).to have_text("States of catalog searching")
      expect(page).to have_text("States and systems")
    end

    scenario "searching with begins_with x OR begins_with y" do
      visit advanced_search_path([
        { field: "title", query: "states", match: "begins_with" },
        { field: "title", query: "introduction", match: "begins_with", op: "should" }
      ])

      expect(page).to have_selector(results_selector)
      expect(page).to have_text("States of catalog searching")
      expect(page).to have_text("Introduction to prefix searching")
    end

    scenario "searching crazy long title with colon in it" do
      title = "Religious liberty : the positive dimension : an address"
      visit advanced_search_path([
        { field: "all_fields", query: title, match: "contains" }
      ])

      expect(page).to have_selector(results_selector, minimum: 1)
      expect(first(results_selector).text).to eq("#{title}")
    end

    scenario "searching crazy long title with colon in it (regular search)" do
      title = "Religious liberty : the positive dimension : an address"
      visit "catalog?#{ {
        search_field: "all_fields", q: title,
      }.to_query}"

      expect(page).to have_selector(results_selector, minimum: 1)
      expect(first(results_selector).text).to eq("#{title}")
    end

    scenario "searching with is operator" do
      visit advanced_search_path([
        { field: "all_fields", query: "introduction to immunology", match: "is" }
      ])

      expect(page).to have_selector(results_selector, minimum: 1)
      expect(first(results_selector).text).to match(/Introduction to immunology/)
    end

    scenario "searching NOT something" do
      visit advanced_search_path([
        { field: "all_fields", query: 'NOT "introduction to immunology"', match: "contains" }
      ])
      expect(page).to have_selector(results_selector, minimum: 10)
      expect(first(results_selector).text).not_to match(/Introduction to immunology/)
    end
  end

  describe "skip links" do

    before do
      stub_request(:get, %r{\Ahttps://api-na\.hosted\.exlibrisgroup\.com/primo/v1/search})
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: File.read("spec/fixtures/articles_search_response.json")
        )
    end

    advanced_search_paths = [
      "/advanced",
      "/articles/advanced",
      "/databases/advanced",
      "/journals/advanced"
    ]

    advanced_search_paths.each do |path|
      scenario "hides Skip to search on #{path}" do
        visit path

        within("#skip-link", visible: :all) do
          expect(page).to have_link(
            "Skip to main content",
            href: "#main-container",
            visible: :all
          )

          expect(page).not_to have_link(
            "Skip to search",
            visible: :all
          )
        end
      end
    end
  end

  def advanced_search_path(clauses)
    "catalog?#{ { clause: clauses.each_with_index.to_h { |clause, index| [index, clause] }, search_field: "advanced" }.to_query }"
  end
end
