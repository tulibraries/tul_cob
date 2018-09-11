# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe CobAlma::Requests do
  describe "picking up at a different campus only" do
    let(:list_items) { Alma::BibItem.find("item").grouped_by_library }
    let(:same_campus) { Alma::BibItem.find("same_campus").grouped_by_library }
    let(:ambler_presser) { Alma::BibItem.find("ambler_presser").grouped_by_library }


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
    let(:kardon_only) { Alma::BibItem.find("kardon_only").grouped_by_library }
    let(:kardon_paley) { Alma::BibItem.find("kardon_paley").grouped_by_library }

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

  describe "#reserve_or_reference" do
    let(:only_paley_reserves) { Alma::BibItem.find("only_paley_reserves").grouped_by_library }
    let(:paley_reserves_and_remote_storage) { Alma::BibItem.find("paley_reserves_and_remote_storage").grouped_by_library }
    let(:no_reserve_or_reference) { Alma::BibItem.find("no_reserve_or_reference").grouped_by_library }
    let(:both_reserve) { Alma::BibItem.find("both_reserve").grouped_by_library }

    it "does not allow a user to request a book, available in Paley reserves, for pickup at Paley" do
      expect(described_class.reserve_or_reference(only_paley_reserves)).to eq []
    end

    it "does allow a user to request a book, available in Paley reserves and Remote Storage, for pickup at Paley" do
      expect(described_class.reserve_or_reference(paley_reserves_and_remote_storage)).to include "MAIN"
    end

    it "does not allow a user to request a book, available in Paley reserves and Remote Storage, for pickup at Kardon" do
      expect(described_class.reserve_or_reference(paley_reserves_and_remote_storage)).not_to include "KARDON"
    end

    it "does not allow a user to request a book, available in Paley stacks, for pickup at Paley" do
      expect(described_class.reserve_or_reference(no_reserve_or_reference)).to eq []
    end

    it "does not allow a user to request a book, available in Paley reserves and Ambler reserves, for pickup at Paley" do
      expect(described_class.reserve_or_reference(both_reserve)).not_to include "MAIN"
    end
  end
end
