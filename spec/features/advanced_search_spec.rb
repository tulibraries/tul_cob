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
        all("div.advanced-search-fields") do
          expect(page).to have_tag("select.advanced-search-select")
          expect(page).to have_tag("input.advanced_search_input")
        end
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
        op_row: ["contains", "contains"],
        f_1: "title", q_1: "full", op_1: "AND",
        f_2: "title", q_2: "exercises",
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_selector(results_selector, count: 1)
      expect(page).to have_text("Title full")
      expect(page).to have_text("Title AND exercises")
      expect(first(results_selector).text).to eq("1. Everyday Activities to Help Your Young Child with Autism Live Life to the Full Simple Exercises to Boost Functional Skills, Sensory Processing, Coordination and Self-Care")
    end

    scenario "searching title for x OR y" do
      visit "catalog?#{{
        op_row: ["contains", "contains"],
        f_1: "title", q_1: "full", op_1: "OR",
        f_2: "title", q_2: "exercises",
        search_field: "advanced",
      }.to_query}"
      expect(page).to have_selector(results_selector, count: 10)
      expect(page).to have_text("Title full")
      expect(page).to have_text("Title OR exercises")
    end

    scenario "searching title for x NOT y" do
      visit "catalog?#{{
        op_row: ["contains", "contains"],
        f_1: "title", q_1: "full", op_1: "NOT",
        f_2: "title", q_2: "exercises",
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_text("Title full")
      expect(page).to have_text("Title NOT exercises")
    end


    scenario "searching with begins_with" do
      visit "catalog?#{{
        op_row: ["begins_with"],
        f_1: "title", q_1: "full",
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_selector(results_selector, count: 1)
      expect(first(results_selector).text).to match(/^1. Full frontal/)
    end

    scenario "searching with begins_with x OR begins_with y" do
      visit "catalog?#{{
        op_row: ["begins_with", "begins_with"],
        f_1: "title", q_1: "silencio", op_1: "OR",
        f_2: "title", q_2: "full",
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_selector(results_selector)
      expect(first(results_selector).text).to match(/^1. Silencio roto/)
    end

    scenario "searching crazy long title with colon in it" do
      title = "Religious liberty : the positive dimension : an address / by Franklin H. Littell at Doane College on April 26, 1966."
      visit "catalog?#{{
        op_row: ["contains"],
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
        op_row: ["is"],
        f_1: "all_fields", q_1: "introduction to issues",
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_selector(results_selector, count: 1)
      expect(first(results_selector).text).to match(/introduction to issues/)
    end

    scenario "searching NOT something" do
      visit "catalog?#{{
        op_row: ["contains"],
        f_1: "all_fields", q_1: "NOT introduction to issues",
        search_field: "advanced",
      }.to_query}"

      expect(page).to have_selector(results_selector, count: 10)
      expect(first(results_selector).text).not_to match(/introduction to issues/)
    end
  end
end
