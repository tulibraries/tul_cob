# frozen_string_literal: true

require "rails_helper"
require "yaml"
include ApplicationHelper

RSpec.feature "Searches", relevance: true do
  let (:fixtures) {
    YAML.load_file("#{fixture_path}/search_features.yml")
  }
  search_element_id = "search"
  feature "Search all fields" do
    let (:item) { fixtures.fetch("book_search") }
    scenario "Search Title" do
      visit "/"
      fill_in "q", with: item["title"]
      click_button search_element_id
      within first(".document-position-0 h3", text: item["title"]) do
        expect(page).to have_text item["title"]
      end
    end

    scenario "Search ID" do
      visit "/"
      fill_in "q", with: item["doc_id"]
      click_button search_element_id
      within first(".document-position-0 h3", text: item["title"]) do
        expect(page).to have_text item["title"]
      end
    end

    scenario "Search book creator" do
      visit "/"
      fill_in "q", with: item["creator"]
      click_button search_element_id
      within("h3", text: item["title"]) do
        expect(page).to have_text item["title"]
      end
    end

    scenario "Search imprint" do
      visit "/"
      fill_in "q", with: item["imprint"]
      click_button search_element_id
      within first(".document-position-0 h3", text: item["title"]) do
        expect(page).to have_text item["title"]
      end
    end

    scenario "Search physical description" do
      skip "TBD"
      visit "/"
      fill_in "q", with: item["physical_description"]
      click_button search_element_id
      within first(".document-position-0 h3", text: item["title"]) do
        expect(page).to have_text item["title"]
      end
    end

    scenario "Search series title" do
      visit "/"
      fill_in "q", with: item["series_title"]
      click_button search_element_id
      within first(".document-position-0 h3", text: item["title"]) do
        expect(page).to have_text item["title"]
      end
    end

    scenario "Search content" do
      skip "TBD"
      visit "/"
      fill_in "q", with: item["content"]
      click_button search_element_id
      within first(".document-position-0 h3", text: item["title"]) do
        expect(page).to have_text item["title"]
      end
    end

    scenario "Search subject" do
      visit "/"
      fill_in "q", with: item["subject"]
      click_button search_element_id
      within first(".document-position-0 h3", text: item["title"]) do
        expect(page).to have_text item["title"]
      end
    end

    scenario "Search ISBN" do
      visit "/"
      fill_in "q", with: item["isbn"]
      click_button search_element_id
      within first(".document-position-0 h3", text: item["title"]) do
        expect(page).to have_text item["title"]
      end
    end

    scenario "Search LCCN" do
      visit "/"
      fill_in "q", with: item["lccn"]
      click_button search_element_id
      within first(".document-position-0 h3", text: item["title"]) do
        expect(page).to have_text item["title"]
      end
    end
  end

  feature "Search all fields in journals" do
    let (:item) { fixtures.fetch("journal_search") }
    scenario "Search Title" do
      visit "/"
      fill_in "q", with: item["title"]
      click_button search_element_id
      within first(".document-position-0 h3", text: item["title"]) do
        expect(page).to have_text item["title"]
      end
    end

    scenario "Search ID" do
      visit "/"
      fill_in "q", with: item["doc_id"]
      click_button search_element_id
      within first(".document-position-0 h3", text: item["title"]) do
        expect(page).to have_text item["title"]
      end
    end

    scenario "Search journal creator" do
      visit "/"
      fill_in "q", with: item["creator"]
      click_button search_element_id
      within "h3", text: item["title"] do
        expect(page).to have_text item["title"]
      end
    end

    scenario "Search imprint" do
      visit "/"
      fill_in "q", with: item["imprint"]
      click_button search_element_id
      within("h3", text: item["title"]) do
        expect(page).to have_text item["title"]
      end
    end

    scenario "Search physical description" do
      skip "TBD"
      visit "/"
      fill_in "q", with: item["physical_description"]
      click_button search_element_id
      within first(".document-position-0 h3", text: item["title"]) do
        expect(page).to have_text item["title"]
      end
    end

    scenario "Search subject" do
      visit "/"
      fill_in "q", with: item["subject"]
      click_button search_element_id
      within first(".document-position-0 h3", text: item["title"]) do
        expect(page).to have_text item["title"]
      end
    end

    scenario "Search ISSN" do
      visit "/"
      fill_in "q", with: item["issn"]
      click_button search_element_id
      within first(".document-position-0 h3", text: item["title"]) do
        expect(page).to have_text item["title"]
      end
    end

    scenario "Search LCCN" do
      visit "/"
      fill_in "q", with: item["lccn"]
      click_button search_element_id
      within first(".document-position-0 h3", text: item["title"]) do
        expect(page).to have_text item["title"]
      end
    end
  end

  feature "Search for an item with a colon in title" do
    let (:item) { fixtures.fetch("has_a_colon") }
    scenario "using default serch" do
      visit "/"
      fill_in "q", with: item["title_statement"]
      click_button search_element_id
      within(".document-position-0 h3") do
        expect(page).to have_text item["exact_title"]
      end
    end
    scenario "using advanced serch" do
      visit "/advanced"
      fill_in "q_1", with: item["title_statement"]
      click_button "advanced-search-submit"
      within(".document-position-0 h3") do
        expect(page).to have_text item["exact_title"]
      end
    end
  end
end
