# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Library Location Facet" do
  before(:each) do
    visit path
  end

  describe "facet values" do
    context "when the library parent facet is selected" do
      let(:path) { "/catalog?f[library_facet][]=Ambler Campus Library&search_field=all_fields&q=blue" }

      it "shows a remove control next to the selected library" do
        expect(page).to have_css(".blacklight-library_facet .facet-label a.remove")
      end

      it "removes the library filter when selecting a location" do
        ambler_item = page.find(
          ".blacklight-library_facet > .facet-content > .accordion-body > ul.pivot-facet > li",
          text: "Ambler Campus Library",
          match: :first
        )
        stacks_link = ambler_item.find(".pivot-facet-inner a", exact_text: "Stacks")

        expect(stacks_link[:href]).to include("location_facet")
        expect(stacks_link[:href]).not_to include("library_facet")
      end
    end

    context "when a library location facet is selected" do
      let(:path) { "/catalog?f[location_facet][]=Ambler Campus Library - Stacks&search_field=all_fields&q=blue" }

      it "keeps the library facet open" do
        expect(page).to have_css(".blacklight-library_facet .facet-field-heading button[aria-expanded='true']")
        expect(page).to have_css(".blacklight-library_facet .facet-content.show")
      end
    end
  end

  describe "constraints" do
    context "Library and Location facet selected" do
      let(:path) { "/catalog?f[library_facet][]=Ambler Campus Library&f[location_facet][]=Ambler Campus Library - Stacks&search_field=all_fields&q=blue" }

      it "should add a location constraint" do
        expect(page.all(".filter .constraint-value .filterValue").first).to have_text("Ambler Campus Library")
        expect(page.all(".filter .constraint-value .filterValue").last).to have_text("Ambler Campus Library - Stacks")
      end
    end
  end
end
