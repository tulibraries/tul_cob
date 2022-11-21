# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accessibility testing", api: false, js: true do
  xit "validates the home page" do
    visit root_path
    #expect(page).to be_accessible
    expect(page).to be_axe_clean
  end

  xit "validates the catalog page" do
    visit "/catalog"
    fill_in "q", with: "history"
    click_button "search"

    # aria-allowed-role doesn"t like nav[role="region"]
    #expect(page).to be_accessible(skipping: ["aria-allowed-role"])
    expect(page).to be_axe_clean
  end

  xit "validates the single results page" do
    visit solr_document_path("991012171319703811")
    #expect(page).to be_accessible
    expect(page).to be_axe_clean
  end

  def be_accessible(skipping: [])
    # typeahead does funny things with the search bar
    be_axe_clean.excluding(".tt-hint").skipping(skipping + [("color-contrast" if Bootstrap::VERSION < "5")])
  end
end
