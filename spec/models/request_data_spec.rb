# frozen_string_literal: true

require "rails_helper"

RSpec.describe RequestData, type: :model do

  subject { described_class.new(bib_items, params = nil) }

  describe "assigning request levels correctly for ASRS and nonASRS items" do
    let(:bib_items)  { [item1, item2 ] }
    context "default behavior empty list" do
      let(:bib_items) { [] }
      it "should be bib" do
        expect(subject.get_request_level).to eq("bib")
      end
    end
    context "asrs items only without descriptions" do
      let(:item1) {
        Alma::BibItem.new("item_data" => { "library" => { "value" => "ASRS", "description" => "Library" } })
      }
      let(:item2) {
        Alma::BibItem.new("item_data" => { "library" => { "value" => "ASRS", "description" => "Library" } })
      }
      it "should be a bib level request" do
        expect(subject.get_request_level).to eq("bib")
        expect(subject.get_request_level("asrs")).to eq("bib")
      end
    end
    context "asrs items only without descriptions" do
        let(:item1) {
          Alma::BibItem.new("item_data" => { "library" => { "value" => "ASRS", "description" => "Library" } })
        }
        let(:item2) {
          Alma::BibItem.new("item_data" => { "library" => { "value" => "ASRS", "description" => "Library" } })
        }
        it "should be a bib level request" do
          expect(subject.get_request_level).to eq("bib")
          expect(subject.get_request_level("asrs")).to eq("bib")
        end
      end
    context "asrs items only without descriptions" do
      let(:item1) {
        Alma::BibItem.new("item_data" => { "library" => { "value" => "ASRS", "description" => "Library" } })
      }
      let(:item2) {
        Alma::BibItem.new("item_data" => { "library" => { "value" => "ASRS", "description" => "Library" } })
      }
      it "should be a bib level request" do
        expect(subject.get_request_level).to eq("bib")
        expect(subject.get_request_level("asrs")).to eq("bib")
      end
    end
    context "mixed asrs and non asrs items without descriptions" do
      let(:item1) {
        Alma::BibItem.new("item_data" => { "library" => { "value" => "MAIN", "description" => "Library" } })
      }
      let(:item2) {
        Alma::BibItem.new("item_data" => { "library" => { "value" => "ASRS", "description" => "Library" } })
      }
      it "should return bib for non asrs hold requests" do
        expect(subject.get_request_level).to eq("bib")
      end
      it "should return item for asrs hold requests" do
        expect(subject.get_request_level("asrs")).to eq("item")
      end
    end
    context "mixed asrs with descriptions" do
      let(:item1) {
        Alma::BibItem.new("item_data" => { "library" => { "value" => "MAIN", "description" => "Library" }, "description" => "v1" })
      }
      let(:item2) {
        Alma::BibItem.new("item_data" => { "library" => { "value" => "ASRS", "description" => "Library" } })
      }
      it "should return item for non asrs hold requests" do
        expect(subject.get_request_level).to eq("item")
      end
      it "should return item for asrs hold requests" do
        expect(subject.get_request_level("asrs")).to eq("item")
      end
    end
  end

  describe "#item_holding_ids(items_list)" do
    let(:bib_items) { Alma::BibItem.find("multiple_descriptions") }

    context "collects holding ids and item pids for regular items" do
      it "returns hash with item holding ids and item pids" do
        expect(subject.item_holding_ids).to eq("22255855450003811" => "23255855440003811", "22255855480003811" => "23255855460003811")
      end
    end

    context "does not collect holding ids and item pids for items in temporary storage" do
      let(:bib_items) { Alma::BibItem.find("temp_storage") }

      it "returns each material type hash once" do
        expect(subject.item_holding_ids).to eq({})
      end
    end
  end



  describe "picking up at a different campus" do
    context "item available at Ambler Campus Library" do
      let(:bib_items) { Alma::BibItem.find("item") }
      it "allows a user to request item for pickup at Charles" do
        expect(subject.valid_pickup_locations).to include "MAIN"
      end
    end
  end

  describe "picking up at a different library" do
    context "item available at Remote Storage" do
      let(:bib_items) { Alma::BibItem.find("kardon_only") }
      it "allows a user to request item for pickup at Charles" do
        expect(subject.valid_pickup_locations).to include "MAIN"
      end
    end
  end

  describe "picking up MAIN item at Charles" do
    context "items available in the Presser Listening Library and at Charles Library" do
      let(:bib_items) { Alma::BibItem.find("same_campus") }
      it "allows a user to request item for pickup at Charles" do
        expect(subject.valid_pickup_locations).to include "MAIN"
      end
    end
    context "items available in Remote Storage and at Charles Library" do
      let(:bib_items) { Alma::BibItem.find("kardon_paley") }
      it "allows a user to request item for pickup at Charles" do
        expect(subject.valid_pickup_locations).to include "MAIN"
      end
    end
  end

  describe "picking up at a Japan Campus Library" do
    context "item available at Japan only" do
      let(:bib_items) { Alma::BibItem.find("japan_only") }
      it "allows a user to request item for pickup at Japan only" do
        expect(subject.valid_pickup_locations).to include "JAPAN"
        expect(subject.valid_pickup_locations).not_to include "MAIN"
      end
    end
    context "item available at Japan and other libraries" do
      let(:bib_items) { Alma::BibItem.find("japan_with_multiple_libraries") }
      it "allows a user to request item for pickup at Japan and other libraries" do
        expect(subject.valid_pickup_locations).to include "JAPAN"
        expect(subject.valid_pickup_locations).to include "MAIN"
      end
    end
  end

  describe "picking up at a Rome Campus Library" do
    context "item available at Rome only" do
      let(:bib_items) { Alma::BibItem.find("rome_only") }
      it "allows a user to request item for pickup at Rome only" do
        expect(subject.valid_pickup_locations).to include "ROME"
        expect(subject.valid_pickup_locations).not_to include "MAIN"
      end
    end
    context "item available at Rome and other libraries" do
      let(:bib_items) { Alma::BibItem.find("japan_and_rome") }
      it "allows a user to request item for pickup at Rome and Japan" do
        expect(subject.valid_pickup_locations).to include "JAPAN"
        expect(subject.valid_pickup_locations).to include "ROME"
        expect(subject.valid_pickup_locations).not_to include "MAIN"
      end
    end
  end

  describe "#reserve_or_reference" do
    context "item available at MAIN reserves" do
      let(:bib_items) { Alma::BibItem.find("only_paley_reserves") }
      it "does not allow a user to request item for pickup at Charles" do
        expect(subject.reserve_or_reference).to eq []
      end
    end
    context "item available at MAIN reserves and Remote Storage" do
      let(:bib_items) { Alma::BibItem.find("paley_reserves_and_remote_storage") }
      it "does allow a user to request item for pickup at Charles" do
        expect(subject.reserve_or_reference).to include "MAIN"
      end
    end
    context "item available at MAIN reserves and Remote Storage" do
      let(:bib_items) { Alma::BibItem.find("paley_reserves_and_remote_storage") }
      it "does allow a user to request item for pickup at Charles but not Remote Storage" do
        expect(subject.reserve_or_reference).to include "MAIN"
        expect(subject.reserve_or_reference).not_to include "KARDON"
      end
    end
    context "item available at MAIN reserves and Ambler reserves" do
      let(:bib_items) { Alma::BibItem.find("paley_reserves_and_remote_storage") }
      it "does not allow a user to request the item for pickup at Ambler" do
        expect(subject.reserve_or_reference).not_to include "AMBLER"
      end
    end
  end

  describe "#item_level_locations" do
    context "empty hash" do
      let(:bib_items) { Alma::BibItem.find("empty_hash") }
      it "returns an empty hash" do
        expect(subject.item_level_locations).to eq({})
      end
    end
    context "one description includes no libraries" do
      let(:bib_items) { Alma::BibItem.find("desc_with_no_libraries") }
      it "returns a hash with all the campuses" do
        expect(subject.item_level_locations).to eq("v.2 (1974)" => { "Ambler Campus Library" => "AMBLER", "Charles Library" => "MAIN", "Ginsburg Health Science Library" => "GINSBURG", "Harrisburg Campus Library" => "HARRISBURG", "Podiatry Library" => "PODIATRY" })
      end
    end
    context "two descriptions each at one library" do
      let(:bib_items) { Alma::BibItem.find("paley_reserves_and_remote_storage") }
      it "returns a hash with all the campuses" do
        expect(subject.item_level_locations).to eq(
          "v.4 (1976)" => { "Ambler Campus Library" => "AMBLER", "Charles Library" => "MAIN", "Ginsburg Health Science Library" => "GINSBURG", "Harrisburg Campus Library" => "HARRISBURG", "Podiatry Library" => "PODIATRY" },
          "v.5 (1977)" => { "Ambler Campus Library" => "AMBLER", "Charles Library" => "MAIN", "Ginsburg Health Science Library" => "GINSBURG", "Harrisburg Campus Library" => "HARRISBURG", "Podiatry Library" => "PODIATRY" })
      end
    end
    context "one description at multiple libraries" do
      let(:bib_items) { Alma::BibItem.find("desc_with_multiple_libraries") }
      it "returns a hash with all the campuses" do
        expect(subject.item_level_locations).to eq("v.2 (1974)" => { "Charles Library" => "MAIN", "Ginsburg Health Science Library" => "GINSBURG", "Harrisburg Campus Library" => "HARRISBURG", "Podiatry Library" => "PODIATRY" })
      end
    end
    context "descriptions at locations including an international campus" do
      let(:bib_items) { Alma::BibItem.find("rome_with_multiple_libraries") }
      it "returns a hash with the relevent locations" do
        expect(subject.item_level_locations).to eq(
          "" => { "Ambler Campus Library" => "AMBLER", "Charles Library" => "MAIN", "Ginsburg Health Science Library" => "GINSBURG", "Harrisburg Campus Library" => "HARRISBURG", "Podiatry Library" => "PODIATRY" },
          "description for ASRS item" => { "Ambler Campus Library" => "AMBLER", "Charles Library" => "MAIN", "Ginsburg Health Science Library" => "GINSBURG", "Harrisburg Campus Library" => "HARRISBURG", "Podiatry Library" => "PODIATRY" },
          "description for Rome item" => { "Rome Campus Library" => "ROME" })
      end
    end
  end

  describe "#booking_locations" do
    context "libraries include ASRS and another location" do
      let(:bib_items) { Alma::BibItem.find("booking_locations") }
      it "returns Charles Library as the name for ASRS" do
        expect(subject.booking_locations).to include(["MAIN", "Charles Library"])
      end
      it "does not returns other libraries for booking locations" do
        expect(subject.booking_locations).not_to include(["AMBLER", "Ambler Campus Library"])
      end
    end
  end

  describe "#material_types_and_descriptions" do
    context "material type and description" do
      let(:bib_items) { Alma::BibItem.find("multiple_descriptions") }
      it "returns an array of hashes with materials types and descriptions" do
        expect(subject.material_types_and_descriptions).to eq([["DVD", ["sample", "second"]]])
      end
    end
    context "material type with empty description" do
      let(:bib_items) { Alma::BibItem.find("empty_descriptions") }
      it "returns an array of hashes with materials types and blank strings for description" do
        expect(subject.material_types_and_descriptions).to eq([["DVD", [""]]])
      end
    end
  end

  describe "#asrs_material_types_and_descriptions" do
    context "record has multiple empty descriptions" do
      let(:bib_items) { Alma::BibItem.find("asrs_empty_descriptions") }
      it "returns an empty array" do
        expect(subject.asrs_material_types_and_descriptions).to eq([["DVD", [""]]])
      end
    end
    context "record has empty description and is ASRS and available" do
      let(:bib_items) { Alma::BibItem.find("asrs_empty_and_description") }
      it "returns one description and one empty string" do
        expect(subject.asrs_material_types_and_descriptions).to eq([["DVD", ["", "sample"]]])
      end
    end
    context "record has empty description and is ASRS and not available" do
      let(:bib_items) { Alma::BibItem.find("empty_and_description_not_in_place") }
      it "returns an empty list" do
        expect(subject.asrs_material_types_and_descriptions).to eq([])
      end
    end
    context "record many description but none are from ASRS" do
      let(:bib_items) { Alma::BibItem.find("multiple_descriptions") }
      it "returns empty list" do
        expect(subject.asrs_material_types_and_descriptions).to eq([])
      end
    end
    context "record has multiple descriptions that are the same" do
      let(:bib_items) { Alma::BibItem.find("asrs_repeated_descriptions") }
      it "returns unique descriptions" do
        expect(subject.asrs_material_types_and_descriptions).to eq([["DVD", ["sample"]]])
      end
    end
  end

  describe "#material_types" do
    context "record contains the same material type multiple times" do
      let(:bib_items) { Alma::BibItem.find("multiple_descriptions") }
      it "returns each material type hash once" do
        expect(subject.material_types).to eq([{ "desc" => "DVD", "value" => "DVD" }])
      end
    end
    context "record contains the same material type multiple times" do
      let(:bib_items) { Alma::BibItem.find("blank_material_type") }
      it "returns each material type hash once" do
        expect(subject.material_types).to eq([])
      end
    end
  end

  describe "#descriptions" do
    context "record has multiple empty descriptions" do
      let(:bib_items) { Alma::BibItem.find("empty_descriptions") }
      it "returns an array with empty string" do
        expect(subject.descriptions).to eq([""])
      end
    end
    context "record has empty description and description" do
      let(:bib_items) { Alma::BibItem.find("empty_and_description") }
      it "returns single description and empty string" do
        expect(subject.descriptions).to eq(["", "sample"])
      end
    end
    context "record has multiple descriptions that are different" do
      let(:bib_items) { Alma::BibItem.find("multiple_descriptions") }
      it "returns multiple descriptions" do
        expect(subject.descriptions).to eq(["sample", "second"])
      end
    end
    context "record has multiple descriptions that are the same" do
      let(:bib_items) { Alma::BibItem.find("repeated_descriptions") }
      it "returns unique descriptions" do
        expect(subject.descriptions).to eq(["sample"])
      end
    end
  end

end
