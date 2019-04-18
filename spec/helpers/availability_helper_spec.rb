# frozen_string_literal: true

require "spec_helper"
require "rails_helper"

RSpec.describe AvailabilityHelper, type: :helper do
  describe "#availability_status(item)" do
    context "item base_status is 1 and policy is Non-circulating" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "base_status" =>
             { "value" => "1" },
             "policy" =>
             { "desc" => "Non-circulating" },
             "requested" => false,
           }
         )
      end

      it "displays library use only" do
        expect(availability_status(item)).to eq "<span class=\"check\"></span>Library Use Only"
      end
    end

    context "item is located in reserves" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
          {
            "base_status" =>
              { "value" => "1" },
            "policy" =>
              { "desc" => "" },
            "location" =>
              { "value" => "reserve" },
            "requested" => false,
          }
       )
      end

      it "displays library use only" do
        expect(availability_status(item)).to eq "<span class=\"check\"></span>Library Use Only"
      end
    end

    context "item is a bound journal" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
          {
            "base_status" =>
              { "value" => "1" },
            "policy" =>
              { "desc" => "Bound Journal" },
            "requested" => false,
          }
       )
      end

      it "displays library use only" do
        expect(availability_status(item)).to eq "<span class=\"check\"></span>Library Use Only"
      end
    end

    context "item circulation policy is music restricted" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
          {
            "base_status" =>
              { "value" => "1" },
            "policy" =>
              { "desc" => "Music Restricted" },
            "requested" => false,
          }
       )
      end

      it "displays library use only" do
        expect(availability_status(item)).to eq "<span class=\"check\"></span>Library Use Only"
      end
    end

    context "item base_status is 1 and item is requested" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "base_status" =>
             { "value" => "1" },
             "policy" =>
             { "desc" => "Non-circulating" },
             "requested" => true,
           }
         )
      end

      it "displays requested" do
        expect(availability_status(item)).to eq "<span class=\"close-icon\"></span>Requested"
      end
    end

    context "item base_status is 1" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "base_status" =>
             { "value" => "1" },
             "policy" =>
             { "desc" => "" },
             "requested" => false,
             "physical_material_type" =>
               { "desc" => "" },
           }
         )
      end

      it "displays available" do
        expect(availability_status(item)).to eq "<span class=\"check\"></span>Available"
      end
    end

    context "item base_status is 0" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "base_status" =>
             { "value" => "0" },
             "process_type" => { "value" => "ILL" }
           }
         )
      end

      it "displays unavailable" do
        expect(availability_status(item)).to eq "<span class=\"close-icon\"></span>At another institution"
      end
    end
  end

  describe "#unavailable_items(item)" do
    context "item includes process_type" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "base_status" =>
             { "value" => "0" },
             "process_type" => { "value" => "ILL" }
           }
         )
      end
      it "displays process type" do
        expect(unavailable_items(item)).to eq "<span class=\"close-icon\"></span>At another institution"
      end
    end

    context "item is requested" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "requested" => true }
         )
      end

      it "displays requested" do
        expect(unavailable_items(item)).to eq "<span class=\"close-icon\"></span>Requested"
      end
    end

    context "item includes process_type not found in mappings" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "base_status" =>
             { "value" => "0" },
             "process_type" => { "value" => "Sample" }
           }
         )
      end

      it "displays default message" do
        expect(unavailable_items(item)).to eq "<span class=\"close-icon\"></span>Checked out or currently unavailable"
      end
    end

    context "item has no process_type" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "base_status" =>
             { "value" => "0" }
           }
         )
      end

      it "displays default message" do
        expect(unavailable_items(item)).to eq "<span class=\"close-icon\"></span>Checked out or currently unavailable"
      end
    end
  end

  describe "#document_and_api_merged_results(document, items_list)" do
    context "item_pid from api matches item_pid in document" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "AMBLER",
        "permanent_location" => "media",
        "current_library" => "AMBLER",
        "current_location" => "media",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811" }]
          }
        }

      let(:items_list) { Alma::BibItem.find("merge_document_and_api") }

      it "merges the availability into the document field" do
        expect(document_and_api_merged_results(document, items_list)).to eq("AMBLER" => [{ "item_pid" => "23237957740003811",
                                                                            "item_policy" => "5",
                                                                            "permanent_library" => "AMBLER",
                                                                            "permanent_location" => "media",
                                                                            "current_library" => "AMBLER",
                                                                            "current_location" => "media",
                                                                            "call_number" => "DVD 13 A165",
                                                                            "holding_id" => "22237957750003811",
                                                                            availability: "<span class=\"check\"></span>Available" }])
      end
    end

    context "item_pid from api does not match item_pid in document" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "12345",
        "item_policy" => "5",
        "permanent_library" => "AMBLER",
        "permanent_location" => "media",
        "current_library" => "AMBLER",
        "current_location" => "media",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811" }]
          }
        }

      let(:items_list) { Alma::BibItem.find("merge_document_and_api") }

      it "does not merge the availability into the document field" do
        expect(document_and_api_merged_results(document, items_list)).to eq({})
      end
    end

    context "does not include missing or lost items" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "12345",
        "item_policy" => "5",
        "permanent_library" => "AMBLER",
        "permanent_location" => "media",
        "current_library" => "AMBLER",
        "current_location" => "media",
        "call_number" => "DVD 13 A165",
        "process_type" => "MISSING",
        "holding_id" => "22237957750003811" }]
          }
        }

      let(:items_list) { Alma::BibItem.find("merge_document_and_api") }

      it "filters out missing or lost items" do
        expect(document_and_api_merged_results(document, items_list)).to eq({})
      end
    end
  end

  describe "#description(item)" do
    context "item includes description" do
      let(:item) { { "description" => "v. 1" } }

      it "displays description" do
        expect(description(item)).to eq "Description: v. 1"
      end
    end

    context "item does NOT include description" do
      let(:item) { {} }

      it "displays nothing" do
        expect(description(item)).to eq ""
      end
    end
  end

  describe "#material_type(item)" do
    context "item includes physical_material_type" do
      let(:item) { { "material_type" => "RECORD" } }

      it "displays physical_material_type" do
        expect(material_type(item)).to eq "Sound Recording"
      end
    end

    context "item does NOT include PHYSICAL_TYPE_EXCLUSIONS" do
      let(:item) { { "material_type" => "BOOK" } }

      it "displays nothing" do
        expect(material_type(item)).to eq nil
      end
    end

    context "item does not include a physical_material_type" do
      let(:item) { {} }

      it "displays nothing" do
        expect(material_type(item)).to eq nil
      end
    end
  end

  describe "#public_note(item)" do
    context "item includes public note" do
      let(:item) { { "public_note" => "Sample note" } }

      it "displays note" do
        expect(public_note(item)).to eq "Note: Sample note"
      end
    end

    context "item does NOT include public note" do
      let(:item) { {} }

      it "displays nothing" do
        expect(public_note(item)).to eq ""
      end
    end
  end

  describe "#missing_or_lost(item)" do
    context "an item is missing" do
      let(:item) { { "item_pid" => "23237957740003811",
      "item_policy" => "5",
      "permanent_library" => "AMBLER",
      "permanent_location" => "media",
      "current_library" => "AMBLER",
      "current_location" => "media",
      "call_number" => "DVD 13 A165",
      "holding_id" => "22237957750003811",
      "process_type" => "MISSING" }
    }

      it "correctly identifies missing items" do
        expect(missing_or_lost?(item)).to be true
      end
    end

    context "an item is not missing or lost" do
      let(:item) { { "item_pid" => "23237957740003811",
      "item_policy" => "5",
      "permanent_library" => "AMBLER",
      "permanent_location" => "media",
      "current_library" => "AMBLER",
      "current_location" => "media",
      "call_number" => "DVD 13 A165",
      "holding_id" => "22237957750003811" }
    }

      it "correctly identifies non-missing items" do
        expect(missing_or_lost?(item)).to be false
      end
    end
  end

  describe "#unwanted(item)" do
    context "an item is missing" do
      let(:item) { { "item_pid" => "23237957740003811",
      "item_policy" => "5",
      "permanent_library" => "AMBLER",
      "permanent_location" => "techserv",
      "current_library" => "AMBLER",
      "current_location" => "techserv",
      "call_number" => "DVD 13 A165",
      "holding_id" => "22237957750003811",
      "process_type" => "MISSING" }
    }

      it "correctly identifies techserv items" do
        expect(unwanted_library_locations(item)).to be true
      end
    end

    context "an item is an unwanted library" do
      let(:item) { { "item_pid" => "23237957740003811",
      "item_policy" => "5",
      "permanent_library" => "AMBLER",
      "permanent_location" => "stacks",
      "current_library" => "EMPTY",
      "call_number" => "DVD 13 A165",
      "holding_id" => "22237957750003811" }
    }

      it "correctly identifies unwanted library" do
        expect(unwanted_library_locations(item)).to be true
      end
    end

    context "an item is not in an unwanted location" do
      let(:item) { { "item_pid" => "23237957740003811",
      "item_policy" => "5",
      "permanent_library" => "AMBLER",
      "permanent_location" => "media",
      "current_library" => "AMBLER",
      "current_location" => "media",
      "call_number" => "DVD 13 A165",
      "holding_id" => "22237957750003811" }
    }

      it "correctly identifies other locations" do
        expect(unwanted_library_locations(item)).to be false
      end
    end
  end

  describe "#library(item)" do
    context "item is in temporary library" do
      let(:item) { { "current_library" => "RES_SHARE" } }

      it "displays temporary library" do
        expect(library(item)).to eq "RES_SHARE"
      end
    end

    context "item is NOT in temporary library" do
      let(:item) { { "permanent_library" => "MAIN" } }

      it "displays library" do
        expect(library(item)).to eq "MAIN"
      end
    end
  end

  describe "#location(item)" do
    context "item is in temporary location" do
      let(:item) { { "current_location" => "ILL" } }

      it "displays temporary location" do
        expect(location_status(item)).to eq "ILL"
      end
    end

    context "item is NOT in temporary location" do
      let(:item) { { "permanent_location" => "rarestacks" } }

      it "displays location and call number" do
        expect(location_status(item)).to eq "rarestacks"
      end
    end
  end

  describe "#location_name_from_short_code(item)" do
    context "location codes are converted to names using translation map" do
      let(:item) { { "permanent_location" => "rarestacks",
                      "permanent_library" => "SCRC" } }

      it "displays location name" do
        expect(location_name_from_short_code(item)).to eq "Reading Room"
      end
    end
  end

  describe "#library_name_from_short_code(short_code)" do
    context "library codes are converted to names using translation map" do
      let(:short_code) { "MAIN" }
      it "displays library name" do
        expect(library_name_from_short_code(short_code)).to eq "Paley Library"
      end
    end
  end

  describe "#alternative_call_number(item)" do
    context "item has an alternate call number" do
      let(:item) { { "alt_call_number" => "alternate call number" } }

      it "displays alternate call number" do
        expect(alternative_call_number(item)).to eq "alternate call number"
      end
    end

    context "item does NOT have an alternate call number" do
      let(:item) { { "call_number" => "regular call number" } }

      it "does NOT display alternate call number" do
        expect(alternative_call_number(item)).to eq "regular call number"
      end
    end
  end

  describe "#document_availability_info(document)" do
    context "filters out empty items" do
      let(:document) { {} }

      it "returns an empty hash" do
        expect(document_availability_info(document)).to eq({})
      end
    end

    context "groups by library" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "12345",
        "item_policy" => "5",
        "permanent_library" => "AMBLER",
        "permanent_location" => "media",
        "current_library" => "AMBLER",
        "current_location" => "media",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811" }]
          }
        }

      it "uses the library as a key" do
        expect(document_availability_info(document)).to eq("AMBLER" =>
                                                              [{ "call_number" => "DVD 13 A165",
                                                                "current_library" => "AMBLER",
                                                                "current_location" => "media",
                                                                "holding_id" => "22237957750003811",
                                                                "item_pid" => "12345",
                                                                "item_policy" => "5",
                                                                "permanent_library" => "AMBLER",
                                                                "permanent_location" => "media" }])
      end
    end

    context "does not include missing or lost items" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "12345",
        "item_policy" => "5",
        "permanent_library" => "AMBLER",
        "permanent_location" => "media",
        "current_library" => "AMBLER",
        "current_location" => "media",
        "call_number" => "DVD 13 A165",
        "process_type" => "MISSING",
        "holding_id" => "22237957750003811" }]
          }
        }

      it "filters out missing or lost items" do
        expect(document_availability_info(document)).to eq({})
      end
    end
  end

  describe "#sort_order_for_holdings(grouped_items)" do
    context "items are sorted by library name with Paley first" do
      let(:grouped_items) do { "AMBLER" =>
  [{ "item_pid" => "23239405700003811",
    "item_policy" => "0",
    "permanent_library" => "AMBLER",
    "permanent_location" => "stacks",
    "current_library" => "AMBLER",
    "current_location" => "stacks",
    "call_number_type" => "0",
    "call_number" => "F159.P7 C66 2003",
    "holding_id" => "22239405730003811",
    "availability" => "<span class=\"check\"></span>Available" }],
 "MAIN" =>
  [{ "item_pid" => "23239405740003811",
    "item_policy" => "0",
    "permanent_library" => "MAIN",
    "permanent_location" => "stacks",
    "current_library" => "MAIN",
    "current_location" => "stacks",
    "call_number_type" => "0",
    "call_number" => "F159.P7 C66 2003",
    "holding_id" => "22239405750003811",
    "availability" => "<span class=\"check\"></span>Available" }] }
      end

      it "returns Paley first, then Ambler" do
        expect(sort_order_for_holdings(grouped_items).keys).to eq(["MAIN", "AMBLER"])
      end
    end

    context "items in Kardon sort by Remote Storage, not KARDON" do
      let(:grouped_items) do {
      "KARDON" =>
        [{ "item_pid" => "23243718620003811",
         "item_policy" => "0",
         "permanent_library" => "KARDON",
         "permanent_location" => "p_remote",
         "current_library" => "KARDON",
         "current_location" => "p_remote",
         "call_number_type" => "0",
         "call_number" => "N6853.S49 A4 2001",
         "holding_id" => "22243718630003811",
         "availability" => "<span class=\"check\"></span>Available" }],
      "MAIN" =>
         [{ "item_pid" => "23243718640003811",
         "item_policy" => "0",
         "permanent_library" => "MAIN",
         "permanent_location" => "stacks",
         "current_library" => "MAIN",
         "current_location" => "stacks",
         "call_number_type" => "0",
         "call_number" => "N6853.S49 A4 2001",
         "holding_id" => "22243718650003811",
         "availability" => "<span class=\"check\"></span>Available" }] }
      end

      it "returns Media before Kardon" do
        expect(sort_order_for_holdings(grouped_items).keys).to eq(["MAIN", "KARDON"])
      end
    end

    context "Items are ordered by location after library name" do
      let(:grouped_items) do
        { "MAIN" =>
          [{ "item_pid" => "23242235660003811",
          "item_policy" => "12",
          "description" => "1992-94",
          "permanent_library" => "MAIN",
          "permanent_location" => "stacks",
          "current_library" => "MAIN",
          "current_location" => "stacks",
          "call_number_type" => "0",
          "call_number" => "HV696.F6F624",
          "holding_id" => "22242235730003811",
          "availability" => "<span class=\"check\"></span>Library Use Only" },
         { "item_pid" => "23242235720003811",
          "item_policy" => "12",
          "description" => "1983-1986",
          "permanent_library" => "MAIN",
          "permanent_location" => "reference",
          "current_library" => "MAIN",
          "current_location" => "reference",
          "call_number_type" => "0",
          "call_number" => "HV696.F6F624",
          "holding_id" => "22242235730003811",
          "availability" => "<span class=\"check\"></span>Library Use Only" },
         { "item_pid" => "23242235710003811",
          "item_policy" => "12",
          "description" => "1987-89",
          "permanent_library" => "MAIN",
          "permanent_location" => "serials",
          "current_library" => "MAIN",
          "current_location" => "serials",
          "call_number_type" => "0",
          "call_number" => "HV696.F6F624",
          "holding_id" => "22242235730003811",
          "availability" => "<span class=\"check\"></span>Library Use Only" }] }
      end

      it "returns copies for each library by location" do
        sorted_locations = sort_order_for_holdings(grouped_items)["MAIN"].map { |item| location_name_from_short_code(item) }
        expect(sorted_locations).to eq(["Journals", "Paley Reference", "Stacks"])
      end
    end

    context "Items are ordered by call number after location" do
      let(:grouped_items) do
        { "MAIN" =>
          [{ "item_pid" => "23242235660003811",
          "item_policy" => "12",
          "description" => "1992-94",
          "permanent_library" => "MAIN",
          "permanent_location" => "stacks",
          "current_library" => "MAIN",
          "current_location" => "stacks",
          "call_number_type" => "0",
          "call_number" => "MT655.P45x",
          "holding_id" => "22242235730003811",
          "availability" => "<span class=\"check\"></span>Library Use Only" },
         { "item_pid" => "23242235720003811",
          "item_policy" => "12",
          "description" => "1983-1986",
          "permanent_library" => "MAIN",
          "permanent_location" => "stacks",
          "current_library" => "MAIN",
          "current_location" => "stacks",
          "call_number_type" => "0",
          "call_number" => "HF5006 .I614",
          "holding_id" => "22242235730003811",
          "availability" => "<span class=\"check\"></span>Library Use Only" },
         { "item_pid" => "23242235710003811",
          "item_policy" => "12",
          "description" => "1987-89",
          "permanent_library" => "MAIN",
          "permanent_location" => "stacks",
          "current_library" => "MAIN",
          "current_location" => "stacks",
          "call_number_type" => "0",
          "call_number" => "AC1 .G72",
          "holding_id" => "22242235730003811",
          "availability" => "<span class=\"check\"></span>Library Use Only" }] }
      end

      it "returns copies for each library by call number" do
        sorted_call_numbers = sort_order_for_holdings(grouped_items)["MAIN"].map { |item| alternative_call_number(item) }
        expect(sorted_call_numbers).to eq(["AC1 .G72", "HF5006 .I614", "MT655.P45x"])
      end
    end

    context "Items are ordered by description after call number" do
      let(:grouped_items) do
        { "MAIN" =>
          [{ "item_pid" => "23242235660003811",
          "item_policy" => "12",
          "description" => "v.55, no.5 (Nov. 2017)",
          "permanent_library" => "MAIN",
          "permanent_location" => "stacks",
          "current_library" => "MAIN",
          "current_location" => "stacks",
          "call_number_type" => "0",
          "call_number" => "MT655.P45x",
          "holding_id" => "22242235730003811" },
         { "item_pid" => "23242235720003811",
          "item_policy" => "12",
          "description" => "v.53 (2016)",
          "permanent_library" => "MAIN",
          "permanent_location" => "stacks",
          "current_library" => "MAIN",
          "current_location" => "stacks",
          "call_number_type" => "0",
          "call_number" => "MT655.P45x",
          "holding_id" => "22242235730003811" },
         { "item_pid" => "23242235710003811",
          "item_policy" => "12",
          "description" => "v.42 (2004)",
          "permanent_library" => "MAIN",
          "permanent_location" => "stacks",
          "current_library" => "MAIN",
          "current_location" => "stacks",
          "call_number_type" => "0",
          "call_number" => "MT655.P45x",
          "holding_id" => "22242235730003811" }] }
      end

      it "returns copies for each library by description" do
        sorted_descriptions = sort_order_for_holdings(grouped_items)["MAIN"].map { |item| description(item) }
        expect(sorted_descriptions).to eq(["Description: v.42 (2004)", "Description: v.53 (2016)", "Description: v.55, no.5 (Nov. 2017)"])
      end
    end
  end

  describe "#render_location_selector" do
    let(:materials) { [] }
    let(:doc) { SolrDocument.new({}) }

    before(:each) do
      allow(helper).to receive(:render)
      allow(doc).to receive(:materials) { materials }
      helper.render_location_selector(doc)
    end

    context "there are no materials" do
      it "should not render a selector" do
        expect(helper).to_not have_received(:render)
      end
    end

    context "there is one material" do
      let(:materials) { ["ONE material"] }

      it "should render the single field selector template" do
        expect(helper).to have_received(:render)
          .with(template: "almaws/_location_field", locals: { material: "ONE material" })
      end
    end

    context "there is more than one material" do
      let(:materials) { [ "ONE material", "TWO materialS" ] }

      it "should render the material selector template" do
        expect(helper).to have_received(:render)
          .with(template: "almaws/_location_selector", locals:
        { materials: [ "ONE material", "TWO materialS" ] })
      end
    end
  end

  describe "#render_non_available_status_only" do
    let(:availability) { "Available" }

    before(:each) do
      allow(helper).to receive(:render) { "" }
      helper.render_non_available_status_only(availability)
    end

    context "material is available" do
      it "does not render _avaiability_status partial" do
        expect(helper).to_not have_received(:render)
      end
    end

    context "material is not available" do
      let (:availability) { "not available" }

      it "does render the _avaiability_status partial" do
        expect(helper).to have_received(:render).with(template: "almaws/_availability_status", locals: { availability: availability })
      end
    end
  end
end
