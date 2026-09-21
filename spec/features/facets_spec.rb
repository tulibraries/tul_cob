# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Facets" do
  it "is able to expand facets when javascript is enabled", js: true do
    visit "/catalog?search_field=all_fields&q=BlacklightTestRecord2"

    within "#facets" do
      if has_css?("#filter-mobile", visible: true)
        find("#filter-mobile").click
        expect(page).to have_css("#facet-panel-collapse.show", visible: true)
      end

      within ".blacklight-library_facet" do
        expect(page).to have_selector(".facet-field-heading button[aria-expanded='false']")

        find(".facet-field-heading button").click

        expect(page).to have_selector(".facet-field-heading button[aria-expanded='true']")
        expect(page).to have_css(".facet-content.show", visible: true)
      end
    end
  end
end
