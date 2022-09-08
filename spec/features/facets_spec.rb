# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Facets" do


  it "is able to expand facets when javascript is enabled", js: true do
    visit "/catalog?search_field=all_fields&q=test"

    expect(page).to have_css("#facet-library_facet", visible: false)

    page.find("#facet-library_facet-header").click()

    sleep(1) # let facet animation finish and wait for it to potentially re-collapse

    expect(page).to have_css("#facet-library_facet", visible: true)
  end
end
