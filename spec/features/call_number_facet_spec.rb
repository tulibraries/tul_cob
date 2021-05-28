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
        expect(page.all(".filter .constraint-value .filterValue").first).to have_text("G - Geography, Anthropology, Recreation | GF - Human Ecology, Anthropogeography")
        expect(page.all(".filter .constraint-value .filterValue").last).to have_text("G - Geography, Anthropology, Recreation | GF - Human Ecology, Anthropogeography")
      end
    end
  end
end
