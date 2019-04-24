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
      expect(page).to have_text("1. The Quality of Life")
    end

    within first("button#many_links_online") do
      expect(page).to have_text "Request Rapid Access"
    end

    expect(page).to have_link "Log in to access request form"
  end

  scenario "View PO Doc" do
    visit "/catalog/991036931835603811"

    expect(page).to have_text "Request Rapid Access"
    expect(page).to have_link "Log in to access request form"
  end

  context "Logged in" do
    before do
      DatabaseCleaner.clean
      user = FactoryBot.create(:user)
      login_as(user, scope: :user)
    end

    scenario "Search PO" do

      visit "/catalog"
      fill_in "q", with: "991036931835603811"
      click_button "search"
      expect(current_url).to eq "http://www.example.com/catalog?utf8=%E2%9C%93&search_field=all_fields&q=991036931835603811"

      expect(page).to have_text "Request Rapid Access"
      expect(page).to_not have_link "Log in to access request form"
    end

    scenario "View PO Doc" do
      visit "/catalog/991036931835603811"

      expect(page).to have_text "Request Rapid Access"
      expect(page).to_not have_link "Log in to access request form"
    end
  end
end
