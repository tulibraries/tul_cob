# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlmaDataHelper, type: :helper do
  describe "#availability_status(item)" do
    context "item base_status is 1 and policy is Non-circulating" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "base_status" =>
             { "value" => "1" },
             "policy" =>
             { "desc" => "Non-circulating" }
           }
         )
      end

      it "displays library use only" do
        expect(availability_status(item)).to eq "<span class=\"check\"></span>Library Use Only"
      end
    end

    context "item base_status is 1" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "base_status" =>
             { "value" => "1" },
             "policy" =>
             { "desc" => "" }
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

  describe "#description(item)" do
    context "item includes description" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "description" => "v. 1" }
         )
      end

      it "displays description" do
        expect(description(item)).to eq "Description: v. 1"
      end
    end

    context "item does NOT include description" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "description" => "" }
         )
      end

      it "displays nothing" do
        expect(description(item)).to eq nil
      end
    end
  end

  describe "#physical_material_type(item)" do
    context "item includes physical_material_type" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "physical_material_type" =>
             { "value" => "RECORD",
                "desc" => "Sound Recording" }
           }
         )
      end

      it "displays physical_material_type" do
        expect(physical_material_type(item)).to eq "Sound Recording"
      end
    end

    context "item does NOT include PHYSICAL_TYPE_EXCLUSIONS" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "physical_material_type" =>
             { "value" => "BOOK" }
           }
         )
      end

      it "displays nothing" do
        expect(physical_material_type(item)).to eq nil
      end
    end

    context "item does not include a physical_material_type" do
      let(:item) { Alma::BibItem.new("item_data" => {}) }

      it "displays nothing" do
        expect(physical_material_type(item)).to eq nil
      end
    end

    context "item contains bad physical_material_type data" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "physical_material_type" =>
             { "value" => nil }
           }
         )
      end
      it "displays nothing" do
        expect(physical_material_type(item)).to eq nil
      end
    end

  end

  describe "#public_note(item)" do
    context "item includes public note" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "public_note" => "example" }
         )
      end

      it "displays note" do
        expect(public_note(item)).to eq "Note: example"
      end
    end

    context "item does NOT include public note" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
         { "public_note" => "" }
       )
      end

      it "displays nothing" do
        expect(public_note(item)).to eq nil
      end
    end
  end

  describe "#location_status(item)" do
    context "item is in temporary location" do
      let(:item) do
        Alma::BibItem.new("holding_data" =>
         { "in_temp_location" => true,
           "temp_library" => { "value" => "RES_SHARE" },
           "temp_location" => { "value" => "IN_RS_REQ" },
           "temp_call_number" => "Temp call number"
          }
       )
      end

      it "displays temporary location and call number" do
        expect(location_status(item)).to eq "Lending Resource Sharing Requests"
      end
    end

    context "item is NOT in temporary location" do
      let(:item) do
        Alma::BibItem.new("holding_data" =>
         { "in_temp_location" => false,
           "call_number" => "Perm call number"
         },
         "item_data" => {
           "library" => { "value" => "MAIN" },
           "location" => { "value" => "stacks" },
         }
       )
      end

      it "displays location and call number" do
        expect(location_status(item)).to eq "Stacks"
      end
    end
  end

  #  describe "#group_and_order_items(item)" do
  #    context "does not display items that are lost" do
  #      let(:item) do
  #          Alma::BibItem.new([{ "holding_data" =>
  #           { "in_temp_location" => false,
  #           },
  #           "item_data" => {
  #             "library" => { "value" => "MAIN" },
  #             "process_type" => { "value" => "LOST_LOAN" }
  #           }
  #         }]
  #      end
  #
  #      it "does not display lost item" do
  #        expect(group_and_order_items(item)).to eq({})
  #      end
  #    end
  #
  #    context "does not display items that are missing" do
  #      let(:item) do
  #        [{ "holding_data" =>
  #           { "in_temp_location" => false,
  #           },
  #           "item_data" => {
  #             "library" => { "value" => "MAIN" },
  #             "process_type" => { "value" => "MISSING" }
  #           }
  #         }]
  #      end
  #
  #      it "does not display missing item" do
  #        expect(group_and_order_items(item)).to eq({})
  #      end
  #    end
  #
  #
  #    context "item is in a permanent library" do
  #      let(:item) do
  #        [{ "holding_data" =>
  #           { "in_temp_location" => false,
  #           },
  #           "item_data" => {
  #             "library" => { "value" => "MAIN" },
  #             "location" => { "value" => "" },
  #             "process_type" => { "value" => "" }
  #           }
  #         }]
  #      end
  #
  #      it "displays library code" do
  #        expect(group_and_order_items(item)).to eq "MAIN" => [{ "holding_data" => { "in_temp_location" => false }, "item_data" => { "library" => { "value" => "MAIN" }, "location" => { "value" => "" }, "process_type" => { "value" => "" }
  # } }]
  #      end
  #    end
  #
  #    context "item is in a temporary library" do
  #      let(:item) do
  #        [{ "holding_data" =>
  #           { "in_temp_location" => true,
  #             "temp_library" => { "value" => "RES_SHARE" },
  #             "temp_location" => { "value" => "IN_RS_REQ" }
  #           },
  #           "item_data" => {
  #             "library" => { "value" => "MAIN" },
  #             "process_type" => { "value" => "" }
  #           }
  #         }]
  #      end
  #
  #      it "displays temporary library code" do
  #        expect(group_and_order_items(item).keys).to have_text "RES_SHARE"
  #      end
  #    end
  #  end

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
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "alternative_call_number" => "alternate" }
        )
      end

      it "displays alternate call number" do
        expect(alternative_call_number(item)).to eq "(Also found under alternate)"
      end
    end
  end

  describe "#sort_order_for_holdings(items)" do
    context "items are sorted by library name with Paley first" do
      let(:items) do
        {
        "MAIN" => [Alma::BibItem.new({})],
        "AMBLER" => [Alma::BibItem.new({})]
      }
      end

      it "returns Paley first, then Ambler" do
        expect(sort_order_for_holdings(items).keys).to eq(["MAIN", "AMBLER"])
      end
    end

    context "items in Kardon sort by Remote Storage, not KARDON" do
      let(:items) do
        {
          "KARDON" => [Alma::BibItem.new({})],
          "MEDIA" =>  [Alma::BibItem.new({})]
        }
      end

      it "returns Media before Kardon" do
        expect(sort_order_for_holdings(items).keys).to eq(["MEDIA", "KARDON"])
      end
    end

    context "Items are ordered by location after library name" do
      let(:items) do
        { "MAIN" => [ Alma::BibItem.new(
          "holding_data" =>
             { "in_temp_location" => false
          },
          "item_data" => {
            "library" => { "value" => "MAIN" },
            "location" => { "value" => "stacks" }
          }
        ),  Alma::BibItem.new(
          "holding_data" =>
             { "in_temp_location" => false
          },
          "item_data" => {
            "library" => { "value" => "MAIN" },
            "location" => { "value" => "serials" }
          }
        ),  Alma::BibItem.new(
          "holding_data" =>
             { "in_temp_location" => false
          },
          "item_data" => {
            "library" => { "value" => "MAIN" },
            "location" => { "value" => "reference" }
            }
          )]
        }
      end

      it "returns copies for each library by location" do

        sorted_locations = sort_order_for_holdings(items)["MAIN"].map(&:location)
        expect(sorted_locations).to eq(["serials", "reference", "stacks"])
      end
    end

    context "Items are ordered by call number after location" do
      let(:items) do
        { "MAIN" => [Alma::BibItem.new(
          "holding_data" =>
             { "in_temp_location" => false,
               "call_number" => "MT655.P45x"
          },
          "item_data" => {
            "library" => { "value" => "MAIN" },
            "location" => { "value" => "stacks" }
          }
        ), Alma::BibItem.new(
          "holding_data" =>
             { "in_temp_location" => false,
               "call_number" => "AC1 .G72"

          },
          "item_data" => {
            "library" => { "value" => "MAIN" },
            "location" => { "value" => "stacks" }
          }
        ), Alma::BibItem.new(
          "holding_data" =>
             { "in_temp_location" => false,
               "call_number" => "HF5006 .I614"
          },
          "item_data" => {
            "library" => { "value" => "MAIN" },
            "location" => { "value" => "stacks" }
            }
          )]
        }
      end

      it "returns copies for each library by call number" do
        sorted_call_numbers = sort_order_for_holdings(items)["MAIN"].map(&:call_number)
        expect(sorted_call_numbers).to eq(["AC1 .G72", "HF5006 .I614", "MT655.P45x"])
      end
    end

    context "Items are ordered by description after call number" do
      let(:items) do
        { "MAIN" => [Alma::BibItem.new(
          "holding_data" =>
             { "in_temp_location" => false,
               "call_number" => "MT655.P45x"
          },
          "item_data" => {
            "library" => { "value" => "MAIN" },
            "location" => { "value" => "stacks" },
            "description" => "v.55, no.5 (Nov. 2017)"
          }
      ), Alma::BibItem.new(
        "holding_data" =>
           { "in_temp_location" => false,
             "call_number" => "MT655.P45x"

        },
        "item_data" => {
          "library" => { "value" => "MAIN" },
          "location" => { "value" => "stacks" },
          "description" => "v.42 (2004)"
        }
      ), Alma::BibItem.new(
        "holding_data" =>
           { "in_temp_location" => false,
             "call_number" => "MT655.P45x"
        },
        "item_data" => {
          "library" => { "value" => "MAIN" },
          "location" => { "value" => "stacks" },
          "description" => "v.53 (2016)"
          }
        )]
      }
      end

      it "returns copies for each library by description" do
        sorted_descriptions = sort_order_for_holdings(items)["MAIN"].map(&:description)
        expect(sorted_descriptions).to eq(["v.42 (2004)", "v.53 (2016)", "v.55, no.5 (Nov. 2017)"])
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

  describe "#unsuppressed_holdings(items_list, document)" do
    context "holding_id is found in solr" do
      let(:items_list) do
        { "MAIN" => [Alma::BibItem.new(
          "holding_data" =>
             { "holding_id" => "22419862390003811"
          }
      ), Alma::BibItem.new(
        "holding_data" =>
           { "holding_id" => "22426649410003811",
        }
      )]
      }
      end

      let(:document) {
          {
            "holdings_display" => ["22419862390003811"]
          }
        }

      it "returns only items found in both api data and document" do
        unsuppressed_holdings(items_list, document)
        expect(items_list["MAIN"].count).to eq(1)
      end
    end

    context "holding_id is not found in solr" do
      let(:items_list) do
        { "MAIN" => [Alma::BibItem.new(
          "holding_data" =>
             { "holding_id" => "22419862390003811"
          }
      ), Alma::BibItem.new(
        "holding_data" =>
           { "holding_id" => "123",
        }
      )]
      }
      end

      let(:document) {
          {
            "holdings_display" => ["456"]
          }
        }

      it "does not include the item with that holding_id" do
        unsuppressed_holdings(items_list, document)
        expect(items_list["MAIN"].count).to eq(0)
      end
    end

    context "all holding ids are found in document and api data" do
      let(:items_list) do
        { "MAIN" => [Alma::BibItem.new(
          "holding_data" =>
             { "holding_id" => "456"
          }
      ), Alma::BibItem.new(
        "holding_data" =>
           { "holding_id" => "123",
        }
      )]
      }
      end

      let(:document) {
          {
            "holdings_display" => ["456", "123"]
          }
        }

      it "does not include the item with that holding_id" do
        unsuppressed_holdings(items_list, document)
        expect(items_list["MAIN"].count).to eq(2)
      end
    end
  end

  describe "#filter_unwanted_locations(items_list)" do
    context "holding location is techserv" do
      let(:items_list) do
        { "MAIN" => [Alma::BibItem.new(
          "item_data" =>
             { "location" => { "value" => "techserv" }
           }
          )]
        }
      end

      it "does not return the item" do
        filter_unwanted_locations(items_list)
        expect(items_list["MAIN"].count).to eq(0)
      end
    end

    context "holding location is UNASSIGNED" do
      let(:items_list) do
        { "MAIN" => [Alma::BibItem.new(
          "item_data" =>
             { "location" => { "value" => "UNASSIGNED" }
           }
          )]
        }
      end

      it "does not return the item" do
        filter_unwanted_locations(items_list)
        expect(items_list["MAIN"].count).to eq(0)
      end
    end

    context "holding location is itref" do
      let(:items_list) do
        { "MAIN" => [Alma::BibItem.new(
          "item_data" =>
             { "location" => { "value" => "intref" }
           }
          )]
        }
      end

      it "does not return the item" do
        filter_unwanted_locations(items_list)
        expect(items_list["MAIN"].count).to eq(0)
      end
    end

    context "holding location is stacks" do
      let(:items_list) do
        { "MAIN" => [Alma::BibItem.new(
          "item_data" =>
             { "location" => { "value" => "stacks" }
           }
          )]
        }
      end

      it "does not return the item" do
        filter_unwanted_locations(items_list)
        expect(items_list["MAIN"].count).to eq(1)
      end
    end
  end
end
