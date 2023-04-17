# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Accessibility testing", api: false, js: true do
  xit "validates the home page" do
    visit root_path
    expect(page).to be_axe_clean.according_to :wcag2a, :wcag2aa
  end

  xit "validates a catalog search results page" do
    visit "/catalog"
    fill_in "q", with: "history"
    click_button "search"
    expect(page).to be_axe_clean.according_to :wcag2a, :wcag2aa
  end

  xit "validates the full record page for catalog record" do
    visit solr_document_path("991012171319703811")
    expect(page).to be_axe_clean.according_to :wcag2a, :wcag2aa
  end

end
