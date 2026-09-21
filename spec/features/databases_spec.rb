# frozen_string_literal: true

require "rails_helper"
require "yaml"

RSpec.feature "Databases AZ" do
  feature "Search all fields" do
    scenario "Search Title" do
      visit "/databases"
      within("div.input-group") do
        fill_in "q", with: "Mental Measurements Yearbook"
        click_button
      end

      expect(page).to have_text "Mental Measurements Yearbook with Tests in Print"

      expect(page).not_to have_button("Bookmark")
      expect(page).not_to have_button("Remove bookmark")
    end
  end

  feature "Databases Advanced Search Form" do

    scenario "visit page" do
      visit "/databases/advanced"


      expect(page).to have_no_content "Library of Congress Classification Range"
    end

    scenario "uses the database-specific advanced search label" do
      visit "/databases"

      expect(page).to have_link("Advanced Databases Search")
      advanced_search_link = find("a.advanced_search", text: "Advanced Databases Search")
      expect(URI.parse(advanced_search_link[:href]).path).to eq("/databases/advanced")

      visit "/databases/advanced"

      expect(page).to have_selector("h1", text: "Advanced Databases Search")
      expect(page).to have_title(/Advanced Databases Search/)
    end

    scenario "submits an advanced search", js: true do
      visit "/databases/advanced"
      expect(page).to have_css("form.advanced[action='/databases']")
      fill_in "q_1", with: "Mental Measurements Yearbook"
      click_button "advanced-search-submit"

      expect(page).to have_current_path("/databases", ignore_query: true)
      expect(page).not_to have_text("Unsupported Search Query")
      expect(page).to have_text("Mental Measurements Yearbook with Tests in Print")
    end

    scenario "uses the configured facet key for a selected database type" do
      visit "/databases/advanced?#{ { f: { az_format: ["Newspapers"] } }.to_query }"

      expect(page).to have_selector(
        "select#format[name='f[az_format][]'] option[value='Newspapers'][selected]",
        visible: :all
      )
    end
  end
end
