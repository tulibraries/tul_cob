# frozen_string_literal: true

require "rails_helper"
require "yaml"
include ApplicationHelper

RSpec.feature "Advanced Search" do
  let (:fixtures) {
    YAML.load_file("#{fixture_path}/features.yml")
  }

  let (:facets) {
    [ "Library",
      "Resource Type",
      "Availability",
      "Languages",
      "Publication Year"]}

  describe "page displays facets" do
    scenario "User visits advanced search page" do
      visit "/advanced"
      within("form.advanced") do
        all("div.limit-input").each_with_index do |div_panel, i|
          expect(div_panel).to have_text facets[i]
        end
      end
    end
  end

  describe "Searches" do
    let (:results_selector) { "h3.index_title" }

    scenario "searching title for x AND y" do
      visit "catalog?#{{
        operator: ["contains", "contains"],
        f_1: "title", q_1: "united", op_1: "AND",
        f_2: "title", q_2: "states",
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_selector(results_selector, count: 2)
      expect(page).to have_text("Title united")
      expect(page).to have_text("Title AND states")
      expect(first(results_selector).text).to eq("1. Agreement between the government of the United States of America and the government of Canada on Pacific hake/whiting (Treaty Doc. 108-24) : report (to accompany Treaty Doc. 108-24).")
    end

    scenario "searching title for x OR y" do
      visit "catalog?#{{
        operator: ["contains", "contains"],
        f_1: "title", q_1: "united", op_1: "OR",
        f_2: "title", q_2: "states",
        search_field: "advanced",
      }.to_query}"
      expect(page).to have_selector(results_selector, count: 6)
      expect(page).to have_text("Title united")
      expect(page).to have_text("Title OR states")
    end

    scenario "searching title for x NOT y" do
      visit "catalog?#{{
        operator: ["contains", "contains"],
        f_1: "title", q_1: "united", op_1: "NOT",
        f_2: "title", q_2: "states",
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_text("Title united")
      expect(page).to have_text("Title NOT states")
    end


    scenario "searching with begins_with" do
      visit "catalog?#{{
        operator: ["begins_with"],
        f_1: "title", q_1: "states",
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_selector(results_selector, count: 3)
      expect(first(results_selector).text).to match(/^1. States of political discourse/)
    end

    scenario "searching with begins_with x OR begins_with y" do
      visit "catalog?#{{
        operator: ["begins_with", "begins_with"],
        f_1: "title", q_1: "states", op_1: "OR",
        f_2: "title", q_2: "introduction",
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_selector(results_selector)
      expect(first(results_selector).text).to match(/^1. Introduction to immunology/)
    end

    scenario "searching crazy long title with colon in it" do
      title = "Religious liberty : the positive dimension : an address / by Franklin H. Littell at Doane College on April 26, 1966."
      visit "catalog?#{{
        operator: ["contains"],
        f_1: "all_fields", q_1: title,
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_selector(results_selector, count: 1)
      expect(first(results_selector).text).to eq("1. #{title}")
    end

    scenario "searching crazy long title with colon in it (regular search)" do
      title = "Religious liberty : the positive dimension : an address / by Franklin H. Littell at Doane College on April 26, 1966."
      visit "catalog?#{{
        search_field: "all_fields", q: title,
      }.to_query}"

      expect(page).to have_selector(results_selector, count: 1)
      expect(first(results_selector).text).to eq("1. #{title}")
    end
    scenario "searching with is operator" do
      visit "catalog?#{{

        operator: ["is"],
        f_1: "all_fields", q_1: "introduction to immunology",
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_selector(results_selector, count: 1)
      expect(first(results_selector).text).to match(/1. Introduction to immunology/)
    end

    scenario "searching NOT something" do
      visit "catalog?#{{
        operator: ["contains"],
        f_1: "all_fields", q_1: 'NOT "introduction to immunology"',
        search_field: "advanced",
      }.to_query}"
      expect(page).to have_selector(results_selector, count: 10)
      expect(first(results_selector).text).not_to match(/Introduction to immunology/)
    end
  end
end
