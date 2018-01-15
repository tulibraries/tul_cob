# frozen_string_literal: true

require "rails_helper"
require "yaml"

RSpec.feature "Bento Searches" do
  let (:fixtures) {
    YAML.load_file("#{fixture_path}/search_features.yml")
  }
  feature "Search all fields" do
    let (:item) { fixtures.fetch("book_search") }
    scenario "Search Title" do
      visit "/bento"
      within("div.hero-unit") do
        fill_in "q", with: item["title"]
        click_button
      end
      within first("h4") do
        expect(page).to have_text item["title"]
      end
    end
  end

  feature "Blacklight link to full results" do
    let (:item) { fixtures.fetch("book_search") }
    scenario "Blacklight results display link to full results " do
      visit "/bento"
      within("div.hero-unit") do
        fill_in "q", with: item["title"]
        click_button
      end
      within first("div.bento-search-engine") do
        expect(page).to have_css("a.full-results")
      end
    end
  end
end
