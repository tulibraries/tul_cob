# frozen_string_literal: true
require "rails_helper"
require "yaml"
require "spec_helper"



describe Alma::AvailabilityResponse, js: true  do

  before(:all) do
      Alma.configure
    end
    
  feature "Availability Buttons by status" do
    scenario "Available items should have a green button" do
      visit "/"
      fill_in "q", with: "Academic freedom"
      click_button "Search"
      within(".document-position-0 h3") do
        expect(page).to have_css(".btn-success")
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
