# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Call Number Facet" do
  before(:each) do
    visit path
  end

  describe "constraints" do
    context "lc outerfacet selected " do
      let(:path) { "/catalog?f%5Blc_inner_facet%5D%5B%5D=GF+-+Human+Ecology%2C+Anthropogeography&f%5Blc_outer_facet%5D%5B%5D=G+-+Geography%2C+Anthropology%2C+Recreation&f%5Blc_outer_facet%5D%5B%5D=G+-+Geography%2C+Anthropology%2C+Recreation&q=blue&search_field=all_fields" }

      it "should add the lc facets constraints" do
        lc_constraints = page.all(".filter-lc_facet, .filter-lc_inner_facet, .filter-lc_outer_facet")

        expect(lc_constraints.size).to eq(1)
        expect(lc_constraints.first).to have_css(
          ".constraint-value .filterValue",
          text: "G - Geography, Anthropology, Recreation | GF - Human Ecology, Anthropogeography"
        )
      end
    end

    context "Advanced Search Library Of Congress Classification Range search." do
      let(:path) { "http://localhost:3000/catalog?clause%5B0%5D%5Bfield%5D=all_fields&clause%5B0%5D%5Bquery%5D=test&clause%5B0%5D%5Bmatch%5D=contains&range%5Blc_classification%5D%5Bbegin%5D=A&range%5Blc_classification%5D%5Bend%5D=Z&search_field=advanced" }

      it "should add the lc classification constraints" do
        expect(page).to have_css(".constraint-value", text: "Library of Congress Classification")
        expect(page).to have_css(".constraint-value", text: "A to Z")
        expect(page).to have_css(".constraint-value", text: "All Fields test")
        expect(page).not_to have_css(".constraint-value", text: "_query_:")
        expect(page).to have_field("q") { |field| field.value.blank? }
      end

      it "removes the classification range while preserving the query" do
        within(".filter-lc_classification", match: :first) do
          find("a.remove").click
        end

        expect(page).not_to have_css(".filter-lc_classification")
        expect(page).to have_css(".constraint-value", text: "All Fields test")
      end

      it "restores the search fields when returning to advanced search" do
        find("a.advanced_search", match: :first).click

        within("form.advanced") do
          expect(page).to have_field("q_1", with: "test")
          expect(page).to have_select("f_1", selected: "All Fields")
          expect(page).to have_field("range_lc_classification_begin", with: "A")
          expect(page).to have_field("range_lc_classification_end", with: "Z")
        end
      end

      it "renders the facet body using the accordion markup" do
        within(".blacklight-lc_facet") do
          expect(page).to have_selector(".accordion-body", visible: true)
        end
      end
    end
  end
end
