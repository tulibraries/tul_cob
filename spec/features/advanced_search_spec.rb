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
      "Publication Year"]}

  describe "page displays facets" do
    scenario "User visits advanced search page" do
      visit "/advanced"
      within("form.advanced") do
        expect(current_scope).to have_selector("div.advanced-search-facet")
        all("div.advanced-search-facet").each_with_index do |div_panel, i|
          expect(div_panel).to have_text facets[i]
        end
      end
    end
  end

  describe "Searches" do
    let (:results_selector) { "h3.index_title" }

    scenario "searching title for x AND y" do
      visit "catalog?#{{
        operator: { q_1: "contains", q_2: "contains" },
        f_1: "title", q_1: "united", op_1: "AND",
        f_2: "title", q_2: "states",
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_selector(results_selector, minimum: 2)
      expect(page).to have_text("Title united")
      expect(page).to have_text("Title AND states")
      expect(first(results_selector).text.downcase).to include("united", "states")
    end

    scenario "searching title for x OR y" do
      visit "catalog?#{{
        operator: { q_1: "contains", q_2: "contains" },
        f_1: "title", q_1: "united", op_1: "OR",
        f_2: "title", q_2: "states",
        search_field: "advanced",
      }.to_query}"
      expect(page).to have_selector(results_selector, minimum: 6)
      expect(page).to have_text("Title united")
      expect(page).to have_text("Title OR states")
    end

    scenario "searching title for x NOT y" do
      visit "catalog?#{{
        operator: { q_1: "contains", q_2: "contains" },
        f_1: "title", q_1: "united", op_1: "NOT",
        f_2: "title", q_2: "states",
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_text("Title united")
      expect(page).to have_text("Title NOT states")
    end


    scenario "searching with begins_with" do
      visit "catalog?#{{
        operator: { q_1: "begins_with" },
        f_1: "title", q_1: "states",
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_selector(results_selector, minimum: 3)
      expect(first(results_selector).text).to match(/^[Ss]tate/)
    end

    scenario "searching with begins_with x OR begins_with y" do
      visit "catalog?#{{
        operator: { q_1: "begins_with", q_2: "begins_with" },
        f_1: "title", q_1: "states", op_1: "OR",
        f_2: "title", q_2: "introduction",
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_selector(results_selector)
      expect(first(results_selector).text).to match(/^([Ss]tates|[Ii]ntroduction) /)
    end

    scenario "searching crazy long title with colon in it" do
      title = "Religious liberty : the positive dimension : an address"
      visit "catalog?#{{
        operator: { q_1: "contains" },
        f_1: "all_fields", q_1: title,
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_selector(results_selector, minimum: 1)
      expect(first(results_selector).text).to eq("#{title}")
    end

    scenario "searching crazy long title with colon in it (regular search)" do
      title = "Religious liberty : the positive dimension : an address"
      visit "catalog?#{{
        search_field: "all_fields", q: title,
      }.to_query}"

      expect(page).to have_selector(results_selector, minimum: 1)
      expect(first(results_selector).text).to eq("#{title}")
    end
    scenario "searching with is operator" do
      visit "catalog?#{{
        operator: { q_1: "is" },
        f_1: "all_fields", q_1: "introduction to immunology",
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_selector(results_selector, minimum: 1)
      expect(first(results_selector).text).to match(/Introduction to immunology/)
    end

    scenario "searching NOT something" do
      visit "catalog?#{{
        operator: { q_1: "contains" },
        f_1: "all_fields", q_1: 'NOT "introduction to immunology"',
        search_field: "advanced",
      }.to_query}"
      expect(page).to have_selector(results_selector, minimum: 10)
      expect(first(results_selector).text).not_to match(/Introduction to immunology/)
    end
  end
end
