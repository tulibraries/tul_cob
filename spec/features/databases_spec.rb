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

    scenario "submits an advanced search", js: true do
      visit "/databases/advanced"
      fill_in "q_1", with: "Mental Measurements Yearbook"
      click_button "advanced-search-submit"

      expect(current_path).to eq("/databases")
      expect(page).not_to have_text("Unsupported Search Query")
      expect(page).to have_text("Mental Measurements Yearbook with Tests in Print")
    end
  end
end
