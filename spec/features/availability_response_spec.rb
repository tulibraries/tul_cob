# frozen_string_literal: true
require "rails_helper"
require "yaml"

RSpec.feature "Availability" do

  describe Alma::AvailabilityResponse do

    before(:all) do
      Alma.configure
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
end
