require 'rails_helper'
require 'traject'
require 'traject/command_line'
require 'yaml'

RSpec.feature "Indices", type: :feature do
  let (:fixtures) {
    YAML.load_file("#{fixture_path}/features.yml")
  }

  feature "Home Page" do
    context "publicly available pages" do
      scenario "User visits home page" do
        visit '/'
        expect(page).to have_text "Welcome!"
        within("#facets") do
            expect(page).to have_text "Date"
        end
      end

    end
  end

  feature "Catalog" do
    let (:title) { "Academic freedom in an age of conformity" }
    let (:results_url) { "http://www.example.com/?utf8=%E2%9C%93&search_field=all_fields&q=Academic+freedom+in+an+age+of+conformity" }
    scenario "Search" do
      visit '/'
      fill_in 'q', with: title
      click_button 'Search'
      expect(current_url).to eq results_url
      within(".document-position-0 h3") do
        expect(page).to have_text title 
      end
      within(".document-metadata") do
        expect(page).to have_text "Resource Type:"
        expect(page).to have_text "Book and Print"
        expect(page).to have_text "Status/Location:"
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
      visit '/'
      fill_in 'q', with: item['title']
      click_button 'Search'
      expect(current_url).to eq item['url']
      within(".document-position-0") do
        click_link item['title']
        expect(current_url).to eq item_url
        within("h3") do
          expect(page).to have_text item['title']
        end
        click_link item['title']
      end
    end

    scenario "User visits a document directly" do
      visit "catalog/#{item['doc_id']}"
      expect(current_url).to eq item_url
      expect(page).to have_text(item['title'])
    end
  end

  feature "MARC Fields" do
    let (:item) {
      fixtures.fetch("title_statement")
    }

    scenario "User visits a document with full title statement" do
      visit "catalog/#{item['doc_id']}"
      expect(page).to have_text(item['title'])
    end

  end
end
