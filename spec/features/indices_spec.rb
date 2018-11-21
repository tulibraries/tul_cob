# frozen_string_literal: true

require "rails_helper"
require "traject"
require "traject/command_line"
require "yaml"
require "pry"

RSpec.feature "Indices" do
  let (:fixtures) {
    YAML.load_file("#{fixture_path}/features.yml")
  }

  feature "Home Page" do
    context "publicly available pages" do
      scenario "User visits home page" do
        visit "/catalog"
        expect(page).to_not have_css("#facets")
      end
    end
  end

  feature "Catalog" do
    let (:title) { "Academic freedom in an age of conformity" }
    let (:results_url) { "http://www.example.com/catalog?utf8=%E2%9C%93&search_field=all_fields&q=Academic+freedom+in+an+age+of+conformity" }
    scenario "Search" do
      visit "/catalog"
      fill_in "q", with: title
      click_button "search"
      expect(current_url).to eq results_url
      within(".document-position-0 h3") do
        expect(page).to have_text(title)
      end
      within(".document-metadata") do
        expect(page).to have_text "Resource Type:"
        expect(page).to have_text "Book"
        expect(page).to have_text "Author/Creator:"
        expect(page).to have_text "Publication:"
        has_css?(".avail-button", visible: true)
      end
    end
  end

  feature "Document" do
    let (:item) {
      fixtures.fetch("simple_search")
    }

    let (:item_url) {
      "#{Capybara.default_host}/catalog/#{item['doc_id']}"
    }

    scenario "Search" do
      visit "/catalog"
      fill_in "q", with: item["title"]
      click_button "search"
      expect(current_url).to eq item["url"]
      within(".documentHeader") do
        click_link item["title"]
        expect(current_url).to eq item_url
        within("h3") do
          expect(page).to have_text item["title"]
        end
        click_link item["title"]
      end
    end

    scenario "User visits a document directly" do
      visit "catalog/#{item['doc_id']}"
      expect(current_url).to eq item_url
      expect(page).to have_text(item["title"])
    end


    scenario "Login link with proper redirect_to params are on search pages" do
      pending("The expected href appears in the browser, but not in Capybara, ¯\\_(ツ)_/¯")
      visit "catalog/#{item['doc_id']}"
      expect(page).to find(:xpath, "//div[@id='requests-container']/a[contains(@href,'redirect_to')]")
    end

  end
end
