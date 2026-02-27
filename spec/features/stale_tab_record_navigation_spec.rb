# frozen_string_literal: true

require "rails_helper"
require "yaml"

RSpec.feature "Stale tab record navigation" do
  include ActiveSupport::Testing::TimeHelpers

  let(:fixtures) { YAML.load_file("#{fixture_paths}/features.yml") }
  let(:item) { fixtures.fetch("simple_search") }

  scenario "user can click a record from an aged results tab without landing on a 500 page", js: true do
    travel_to(Time.zone.local(2026, 1, 22, 10, 0, 0)) do
      visit "/catalog"
      fill_in "q", with: item["title"]
      click_button "search"

      expect(page).to have_css("#documents")
      expect(page).to have_link(item["title"])
    end

    travel_to(Time.zone.local(2026, 1, 22, 13, 0, 0)) do
      click_link item["title"]

      # Successful record page signal
      expect(page).to have_css("#record-page-container")

      # Guard against known failure pages
      expect(page).not_to have_text("Internal Server Error")
      expect(page).not_to have_text("The requested URL was rejected")
    end
  end
end
