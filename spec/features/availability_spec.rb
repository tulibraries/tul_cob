# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Availability displays" do
  let (:fixtures) {
    YAML.load_file("#{fixture_path}/availability_features.yml")
  }

  feature "ASRS instructions display" do
    let (:item) { fixtures.fetch("asrs_item") }

    scenario "Items in ASRS have retrieval instructions" do
      visit "/catalog/#{item['doc_id']}"
      within first("div.physical-holding-panel") do
        expect(page).not_to have_css("#bookbot-instructions")
      end
    end
  end

  feature "SCRC instructions display" do
    let (:item) { fixtures.fetch("scrc_item") }

    scenario "Items in SCRC have instructions" do
      visit "/catalog/#{item['doc_id']}"
      within first("div.physical-holding-panel") do
        expect(page).to have_css("#scrc-instructions")
      end
    end
  end

  feature "MAIN open shelving instructions display" do
    let (:item) { fixtures.fetch("main_item_open_stacks") }

    scenario "Items in MAIN open shelving have retrieval instructions" do
      visit "/catalog/#{item['doc_id']}"
      within first("div.physical-holding-panel") do
        expect(page).to have_css("#open-shelving-instructions")
      end
    end
  end

  feature "MAIN open shelving instructions do not display for closed stack items" do
    let (:item) { fixtures.fetch("main_item_closed_stacks") }

    scenario "Items in MAIN closed shelving do not display retrieval instructions" do
      visit "/catalog/#{item['doc_id']}"
      expect(page).to_not have_css("#open-shelving-instructions")
    end
  end
end
