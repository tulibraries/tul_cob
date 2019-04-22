# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Bento Availability" do
  let (:fixtures) {
    YAML.load_file("#{fixture_path}/features.yml")
  }

  feature "Online items link to resources" do
    let (:item) { fixtures.fetch("single_online_resource") }
    let (:item_2) { fixtures.fetch("multiple_online_resources") }
    let (:electronic_resource_url) {
      /view\/uresolver\/01TULI_INST\/openurl\?Force_direct=true&portfolio_pid=53395029150003811&rfr_id=info%3Asid%2Fprimo.exlibrisgroup.com&u.ignore_date_coverage=true/
    }
    let (:item_url) {
      "#{Capybara.default_host}/catalog/#{item_2['doc_id']}"
    }

    scenario "Items with a single electronic resource link directly" do
      visit "/bento"
      within("div.input-group") do
        fill_in "q", with: item["doc_id"]
        click_button
      end
      within first("div.bento_item") do
        link_tag = find("a.bento-avail-btn")
        expect(link_tag[:href]).to match(electronic_resource_url)
      end

      within first("div.bento-search-engine") do
        expect(page).to have_css(".full-results")
      end
    end

    scenario "Items with multiple links go to record page" do
      visit "/bento"
      within("div.input-group") do
        fill_in "q", with: item_2["doc_id"]
        click_button
      end
      within first("div.bento_item") do
        link_tag = find("a.bento-avail-btn")
        expect(link_tag[:href]).to eq(item_url)
      end
    end
  end
end
