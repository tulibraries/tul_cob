# frozen_string_literal: true

require "rails_helper"

RSpec.describe Alma::Requests do
  describe "picking up at a different campus only" do
    let(:list_items) { Alma::BibItem.find("item") }
    let(:same_campus) { Alma::BibItem.find("same_campus") }
    let(:ambler_presser) { Alma::BibItem.find("ambler_presser") }


    it "allows a user to request an item, available in the Ambler Campus Library Stacks, for pickup at Paley." do
      expect(described_class.valid_pickup_locations(list_items)).to include "MAIN"
    end

    it "does not allow a user to request an item available in the Presser Listening Library, for pickup at Paley." do
      expect(described_class.valid_pickup_locations(same_campus)).not_to include "MAIN"
    end

    # it "allows a user to request an item, available in the Presser Listening Library and Ambler Campus Library Stacks, for pickup at Paley" do
    #   expect(described_class.valid_pickup_locations(ambler_presser)).to include "MAIN"
    # end
  end

  describe "picking up at a different library only" do
    let(:kardon_only) { Alma::BibItem.find("kardon_only") }
    let(:kardon_paley) { Alma::BibItem.find("kardon_paley") }

    it "allows a user to request a book, available in Remote Storage, for pickup at Paley" do
      expect(described_class.valid_pickup_locations(kardon_only)).to include "MAIN"
    end

    it "allows a user to request a book, available in Remote Storage and at Ambler Campus Library, for pickup at Paley" do
      expect(described_class.valid_pickup_locations(kardon_only)).to include "MAIN"
    end

    it "does not allow a user to request a book, available in Remote Storage and Paley Library Stacks, for pickup at Paley" do
      expect(described_class.valid_pickup_locations(kardon_paley)).not_to include "MAIN"
    end
  end
end
