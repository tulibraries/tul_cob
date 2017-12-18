# frozen_string_literal: true

require "rails_helper"
require "yaml"
include ApplicationHelper

RSpec.feature "Advanced Search", type: :feature do
  let (:fixtures) {
    YAML.load_file("#{fixture_path}/features.yml")
  }

  feature "Advanced Search" do
    let (:facets) {
      [ "Library",
        "Resource Type",
        "Availability",
        "Languages",
        "Publication Year"
      ]
    }
    context "advanced search page displays facets" do
      scenario "User visits advanced search page" do
        visit "/advanced"
        within("form.advanced") do
          all("div.advanced-search-fields") do
            expect(page).to have_tag("select.advanced-search-select")
            expect(page).to have_tag("input.advanced_search_input")
          end
          all("div.limit-input").each_with_index do |div_panel, i|
            expect(div_panel).to have_text facets[i]
          end
        end
      end
    end
  end
end
