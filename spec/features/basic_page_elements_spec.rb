# frozen_string_literal: true

require "rails_helper"


RSpec.feature "Basic Page Elements" do

  feature "Check the home page for nav elements when anonymous" do
    scenario "Go to the home page" do
      visit "/"
      within(".navbar-right") do
        expect(page).to have_text "Bookmarks"
        expect(page).to have_text "My Library Account"
        expect(page).to have_no_text "Library Account"
      end
    end

  end



  feature "Check for home page features when logged in" do

    before do
      DatabaseCleaner.clean
      user = FactoryBot.create(:user)
      login_as(user, scope: :user)

    end

    scenario "Go to the home page" do
      visit "/"
      within(".navbar-right") do
        expect(page).to have_text "My Library Account"
        expect(page).to have_text "Log Out"
      end
    end

    after(:all) do
      DatabaseCleaner.clean
      Warden.test_reset!
    end

  end
end
