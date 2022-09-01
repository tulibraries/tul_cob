# frozen_string_literal: true

require "rails_helper"
require "yaml"
include ApplicationHelper

RSpec.feature "Purchase Order" do

  scenario "Search PO" do
    visit "/catalog"
    fill_in "q", with: "991036931835603811"
    click_button "search"
    expect(current_url).to eq "http://www.example.com/catalog?utf8=%E2%9C%93&search_field=all_fields&q=991036931835603811"

    within(".document-position-0 h3") do
      expect(page).to have_text("The Quality of Life")
    end
  end

end
