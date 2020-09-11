# frozen_string_literal: true

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

  describe "#item_level_locations" do
    let(:items_list) { Alma::BibItem.find("empty_hash") }
    let(:subject) { described_class.item_level_locations(items_list) }

    context "empty hash" do
      it "returns an empty hash" do
        expect(subject).to eq({})
      end
    end

    context "one description includes no libraries" do
      let(:items_list) { Alma::BibItem.find("desc_with_no_libraries") }

      it "returns a hash with all the campuses" do
        expect(subject).to eq("v.2 (1974)" => ["MAIN", "AMBLER", "GINSBURG", "PODIATRY", "HARRISBURG"])
      end
    end

    context "two descriptions each at one library" do
      let(:items_list) { Alma::BibItem.find("paley_reserves_and_remote_storage") }

      it "returns a hash with all the campuses" do
        expect(subject).to eq("v.4 (1976)" => ["AMBLER", "GINSBURG", "PODIATRY", "HARRISBURG"],
                              "v.5 (1977)" => ["MAIN", "AMBLER", "GINSBURG", "PODIATRY", "HARRISBURG"])
      end
    end

    context "one description at multiple libraries" do
      let(:items_list) { Alma::BibItem.find("desc_with_multiple_libraries") }

      it "returns a hash with all the campuses" do
        expect(subject).to eq("v.2 (1974)" => ["GINSBURG", "PODIATRY", "HARRISBURG"])
      end
    end
  end

  describe "#descriptions" do
    context "record has multiple empty descriptions" do
      let(:items_list) { Alma::BibItem.find("empty_descriptions") }

      it "returns an array with empty string" do
        expect(described_class.descriptions(items_list)).to eq([""])
      end
    end

    context "record has empty description and description" do
      let(:items_list) { Alma::BibItem.find("empty_and_description") }

      it "returns single description and empty string" do
        expect(described_class.descriptions(items_list)).to eq(["", "sample"])
      end
    end

    context "record has multiple descriptions that are different" do
      let(:items_list) { Alma::BibItem.find("multiple_descriptions") }

      it "returns multiple descriptions" do
        expect(described_class.descriptions(items_list)).to eq(["sample", "second"])
      end
    end

    context "record has multiple descriptions that are the same" do
      let(:items_list) { Alma::BibItem.find("repeated_descriptions") }

      it "returns unique descriptions" do
        expect(described_class.descriptions(items_list)).to eq(["sample"])
      end
    end
  end

  describe "#material_type_and_asrs_descriptions(items_list)" do
    context "record has multiple empty descriptions" do
      let(:items_list) { Alma::BibItem.find("asrs_empty_descriptions") }

      it "returns an empty array" do
        expect(described_class.material_type_and_asrs_descriptions(items_list)).to eq([["DVD", [""]]])
      end
    end

    context "record has empty description and is ASRS and available" do
      let(:items_list) { Alma::BibItem.find("asrs_empty_and_description") }

      it "returns one description and one empty string" do
        expect(described_class.material_type_and_asrs_descriptions(items_list)).to eq([["DVD", ["", "sample"]]])
      end
    end

    context "record has empty description and is ASRS and not available" do
      let(:items_list) { Alma::BibItem.find("empty_and_description_not_in_place") }

      it "returns an empty list" do
        expect(described_class.material_type_and_asrs_descriptions(items_list)).to eq([])
      end
    end

    context "record many description but none are from ASRS" do
      let(:items_list) { Alma::BibItem.find("multiple_descriptions") }

      it "returns empty list" do
        expect(described_class.material_type_and_asrs_descriptions(items_list)).to eq([])
      end
    end

    context "record has multiple descriptions that are the same" do
      let(:items_list) { Alma::BibItem.find("asrs_repeated_descriptions") }

      it "returns unique descriptions" do
        expect(described_class.material_type_and_asrs_descriptions(items_list)).to eq([["DVD", ["sample"]]])
      end
    end
  end

  describe "#asrs_pickup_locations" do
    it "displays MAIN as the pickup_location" do
      expect(described_class.asrs_pickup_locations).to eq(["MAIN", "AMBLER", "GINSBURG", "PODIATRY", "HARRISBURG"])
    end
  end

  describe "#booking_location" do
    context "libraries include ASRS and another location" do
      let(:items_list) { Alma::BibItem.find("booking_locations") }

      it "returns Charles Library as the name for ASRS" do
        expect(described_class.booking_location(items_list)).to include(["ASRS", "Charles Library"])
      end

      it "returns other libraries with their assigned name" do
        expect(described_class.booking_location(items_list)).to include(["AMBLER", "Ambler Campus Library"])
      end

    end
  end

  describe "#physical_material_type(items_list)" do
    let(:items_list) { Alma::BibItem.find("multiple_descriptions") }

    context "record contains the same material type multiple times" do
      it "returns each material type hash once" do
        expect(described_class.physical_material_type(items_list)).to eq([{ "desc" => "DVD", "value" => "DVD" }])
      end
    end

    context "record contains the same material type multiple times" do
      let(:items_list) { Alma::BibItem.find("blank_material_type") }

      it "returns each material type hash once" do
        expect(described_class.physical_material_type(items_list)).to eq([])
      end
    end
  end

  describe "#physical_material_type_and_descriptions(items_list)" do

    context "material type and description" do
      let(:items_list) { Alma::BibItem.find("multiple_descriptions") }
      it "returns an array of hashes with materials types and descriptions" do
        expect(described_class.physical_material_type_and_descriptions(items_list)).to eq([["DVD", ["sample", "second"]]])
      end
    end

    context "material type with empty description" do
      let(:items_list) { Alma::BibItem.find("empty_descriptions") }
      it "returns an array of hashes with materials types and blank strings for description" do
        expect(described_class.physical_material_type_and_descriptions(items_list)).to eq([["DVD", [""]]])
      end
    end
  end

  describe "#item_holding_ids(items_list)" do
    let(:items_list) { Alma::BibItem.find("multiple_descriptions") }

    context "collects holding ids and item pids for regular items" do
      it "returns hash with item holding ids and item pids" do
        expect(described_class.item_holding_ids(items_list)).to eq("22255855450003811" => "23255855440003811", "22255855480003811" => "23255855460003811")
      end
    end

    context "does not collect holding ids and item pids for items in temporary storage" do
      let(:items_list) { Alma::BibItem.find("temp_storage") }

      it "returns each material type hash once" do
        expect(described_class.item_holding_ids(items_list)).to eq({})
      end
    end
  end

end
