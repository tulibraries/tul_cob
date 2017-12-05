# frozen_string_literal: true
require "rails_helper"
require "yaml"
require "selenium-webdriver"

describe Alma::AvailabilityResponse, js: true  do

  before(:all) do
    Capybara.javascript_driver = :headless_chrome

    Capybara.register_driver :headless_chrome do |app|
      capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
        chromeOptions: { args: %w[headless disable-gpu] }
  )

    Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 desired_capabilities: capabilities)
    end

    Alma.configure
  end

  feature "Availability Buttons by status" do
    scenario "Available items should have a green button" do
      visit "/"
      fill_in "q", with: "Academic freedom"
      click_button "Search"
      wait_for_ajax
      within(".document-position-0") do
        expect(page).to have_css(".btn-success")
      end
    end

    scenario "Items with only a check_holdings status should not have a button" do
      visit "/"
      fill_in "q", with: "Declassified documents quarterly catalog"
      click_button "Search"
      within(".document-position-0") do
        expect(page).to have_no_css(".btn-success" || ".btn-warning")
      end
    end

    scenario "Items with an unavailable status should have a yellow button" do
      visit "/"
      fill_in "q", with: "Vital dust : the origin and evolution of life on earth"
      click_button "Search"
      within(".document-position-0") do
        expect(page).to have_css(".btn-warning")
      end
    end
  end

  describe "availability attribute" do
    let(:availability) { Alma::Bib.get_availability([1, 2]).availability }

    it "returns a hash" do
      expect(availability).to be_a Hash
    end

    it "has the expected keys" do
      expect(availability.keys).to eql %w{1 2}
    end

    describe "availability hash members value" do
      it "has the expected keys" do
        expect(availability["1"]).to have_key "holdings"
      end
    end

    describe "holdings data in availability hash" do
      it "has the expected keys" do
        keys = %w{availability location call_number inventory_type}
        expect(availability["1"]["holdings"].first.keys).to include(*keys)
      end
    end
  end
end
