# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Home Facets" do

  describe "Facets rendered" do
    it "does not render facets on home pages only on search pages" do
      visit "/catalog"
      home_facets = page.all(".facet-values li").length

      visit "/catalog?search_field=all_fields&q=test"
      expect(page).to have_current_path("/catalog?search_field=all_fields&q=test")

      search_facets = page.all(".facet-values li").length
      expect(home_facets).to be < search_facets
    end

    it "assigns a class to resource type facets" do
      visit "/catalog?search_field=all_fields&q=test"
      expect(page).to have_current_path("/catalog?search_field=all_fields&q=test")
      expect(page).to have_css(".facet_select.facet_book")
    end
  end
end
