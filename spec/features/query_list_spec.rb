# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Query List" do
  let (:fixtures) {
    YAML.load_file("#{fixture_path}/features.yml")
  }

  feature "Record Page query lists" do
    let (:item) { fixtures.fetch("simple_search") }

    scenario "displays query lists for catalog" do
      visit "catalog/#{item['doc_id']}"
      expect(page).to have_text("By call number (a-z)")
    end

    let (:item) { fixtures.fetch("url_856_0") }

    scenario "displays query lists for journals" do
      visit "catalog/#{item['doc_id']}"
      expect(page).to have_text("By call number (z-a)")
    end
  end

  feature "Home Page query lists" do
    scenario "displays query lists for bento home page" do
      visit "?"
      expect(page).to have_text("New Musical Scores")
    end

    scenario "displays query lists for catalog home page" do
      visit "catalog/"
      expect(page).to have_text("New Archival Materials")
    end
  end
end
