# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Basic Page Elements" do

  feature "Check the home page for nav elements when anonymous" do
    scenario "Go to the home page" do
      visit "/"
      within("#website-navbar") do
        expect(page).to have_text "About"
        expect(page).to have_text "My Account"
      end
    end

    scenario "Search bar elements are present" do
      visit "/"
      within("#search-navbar") do
        expect(page).to have_text "Library Search"
        expect(page).to have_text "Bookmarks"
      end
    end
  end

  feature "Check for home page features when logged in" do

    before do
      DatabaseCleaner.clean
      user = FactoryBot.build_stubbed(:user)
      login_as(user, scope: :user)

    end

    scenario "Go to the home page" do
      visit "/"
      within("#website-navbar") do
        expect(page).to have_text "My Account"
        # expect(page).to have_text "Log Out"
      end
    end

    after(:all) do
      DatabaseCleaner.clean
      Warden.test_reset!
    end

  end
end
