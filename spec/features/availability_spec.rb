# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Availability displays" do
  let (:fixtures) {
    YAML.load_file("#{fixture_path}/availability_features.yml")
  }

  feature "SCRC instructions display" do
    let (:item) { fixtures.fetch("scrc_item") }

    scenario "Items in SCRC have instructions" do
      visit "/catalog/#{item['doc_id']}"
      within first("div.physical-holding-panel") do
        expect(page).to have_css("#scrc-instructions")
      end
    end
  end
end
