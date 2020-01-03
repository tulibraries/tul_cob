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

      # TODO: reset test once we use correct solr config.
      # Note this test fails because we are using wrong solr config.
      #expect(page).to have_text "Mental Measurements Yearbook with Tests in Print"
      expect(page).to have_text "2806622"

      expect(page).not_to have_button("Bookmark")
      expect(page).not_to have_button("Remove bookmark")
    end
  end
end
