# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Library Location Facet" do
  before(:each) do
    visit URI.encode(path)
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
