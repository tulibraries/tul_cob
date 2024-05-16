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

    context "Advanced Search Library Of Congress Classification Range search." do
      let(:path) { "http://localhost:3000/catalog?utf8=%E2%9C%93&f_1=all_fields&operator%5Bq_1%5D=contains&q_1=test&op_1=AND&f_2=all_fields&operator%5Bq_2%5D=contains&q_2=&op_2=AND&f_3=all_fields&operator%5Bq_3%5D=contains&q_3=&range%5Bpub_date_sort%5D%5Bbegin%5D=&range%5Bpub_date_sort%5D%5Bend%5D=&range%5Blc_classification%5D%5Bbegin%5D=A&range%5Blc_classification%5D%5Bend%5D=Z&sort=score+desc%2C+pub_date_sort+desc%2C+title_sort+asc&search_field=advanced&commit=Search" }

      it "should add the lc classification constraints" do
        expect(page).to have_css(".constraint-value", text: "Library of Congress Classification")
        expect(page).to have_css(".constraint-value", text: "A to Z")
      end

      it "make lc_facet visible when lc range is present" do
        within(".blacklight-lc_facet") do
          expect(page).to have_selector(".card-body", visible: true)
        end
      end
    end
  end
end
