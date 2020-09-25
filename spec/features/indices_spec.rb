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

  feature "Facets" do
    let (:facets) {
      [ "Availability",
        "Library",
        "Resource Type",
        "Date",
        "Author/creator",
        "Topic",
        "Era",
        "Region",
        "Genre",
        "Language",
        "Library of Congress Classification" ]
    }
    context "searching shows all facets" do
      scenario "User searches catalog" do
        visit "/catalog?with_libguides=true&with_call_number_facet=true"
        fill_in "q", with: "*"
        click_button "search"
        facet_headings = page.all(".facet-field-heading")
        expect(facet_headings.size).to eq facets.size
        facets.each_with_index do |facet, i|
          expect(facet_headings[i]).to have_text facet
        end
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
      expect(page).to have_css("#facets")
      within first(".document-position-0 h3") do
        expect(page).to have_text(title)
      end
      within first(".document-metadata") do
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
      within first(".documentHeader h3") do
        expect(page).to have_text item["title"]
      end

      within first(".documentHeader") do
        click_link item["title"]
        expect(current_url).to eq item_url
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

  feature "Pagination" do
    scenario "User tries to access page past 250" do
      visit "/catalog?page=400&q=japan&search_field=all_fields"
      expect(page).to have_text("Sorry, LibrarySearch does not serve more than 250 pages for any query.")
    end
  end

  feature "Sorting" do
    scenario "User requests results sorted by LC call number" do
      visit "/catalog?q=&q=LCSORT+TEST&rows=20&sort=lc_call_number_sort+asc%2C+pub_date_sort+desc&with_call_number_facet=true"
      expect(page.all(".documents-list .document").size).to eq 13
      (1..13).each do |i|
        expect(page.find(".document-position-#{i - 1} h3 a").native.attr("href")).to eq "/catalog/LCSORT_#{i.ordinalize.upcase}"
      end
    end

    scenario "User requests results reverse sorted by LC call number" do
      visit "/catalog?q=&q=LCSORT+TEST&rows=20&sort=lc_call_number_sort+desc%2C+pub_date_sort+desc&with_call_number_facet=true"
      expect(page.all(".documents-list .document").size).to eq 13
      (1..13).each do |i|
        expect(page.find(".document-position-#{13 - i} h3 a").native.attr("href")).to eq "/catalog/LCSORT_#{i.ordinalize.upcase}"
      end
    end

    feature "Lib Guides section" do
      scenario "Bookmarks page" do
        visit "/bookmarks"
        expect(page).to_not have_css(".lib-guides-recommender-catalog")
      end

      scenario "Catalog page with_libguides=true" do
        visit "/catalog?utf8=%E2%9C%93&search_field=all_fields&q=japan&with_libguides=true"
        expect(page).to have_css(".lib-guides-recommender-catalog")
      end

      scenario "Catalog page with_libguides=false" do
        visit "/catalog?utf8=%E2%9C%93&search_field=all_fields&q=japan&with_libguides=false"
        expect(page).to_not have_css(".lib-guides-recommender-catalog")
      end
    end
  end
end
