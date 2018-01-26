# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Advanced Search" do

  describe "Facets rendered" do
    it "Only a subset of all the facets render on the homepage" do
      visit "/catalog?search_field=all_fields&q_1=x"
      search_facets = page.all(".facet_limit").length

      visit "/catalog"
      home_facets = page.all(".facet_limit").length
      expect(home_facets).to be < search_facets
    end
  end
end
