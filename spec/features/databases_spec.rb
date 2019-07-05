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
    end
  end
end
