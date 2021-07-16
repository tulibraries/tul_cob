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
      expect(page).to have_text("Call Number Asc")
    end

    let (:item) { fixtures.fetch("url_856_0") }

    scenario "displays query lists for journals" do
      visit "catalog/#{item['doc_id']}"
      expect(page).to have_text("Call Number Desc")
    end
  end
end
