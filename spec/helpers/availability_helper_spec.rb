# frozen_string_literal: true

require "rails_helper"

RSpec.describe AvailabilityHelper, type: :helper do
  describe "#availability_status(item)" do
    let(:campus_closed?) { true }

    before do
      allow(helper).to receive(:campus_closed?) { campus_closed? }
    end

    context "item is in temporary MAIN storage" do
      let(:item) do
        Alma::BibItem.new("item_data" => { "current_location" => "storage" })
      end

      it "displays Temporarily unavailable" do
        label = "<span class=\"close-icon\"></span>Temporarily unavailable"
      end
    end

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
        expect(availability_status(item)).to include("Onsite only")
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
        expect(availability_status(item)).to include("Onsite only")
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
        expect(availability_status(item)).to include("Onsite only")
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

      it "displays as available" do
        expect(availability_status(item)).to eq "<span class=\"check\"></span>Available"
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
        expect(availability_status(item)).to eq "<span class=\"check\"></span>Available (Pending Request)"
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

    context "item is on loan" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "base_status" =>
             { "value" => "0" },
             "process_type" => { "value" => "LOAN" },
             "due_date" => "2020-09-01T20:00:00Z"
           }
         )
      end

      it "displays unavailable" do
        expect(availability_status(item)).to eq "<span class=\"close-icon\"></span>Checked out, due 09/01/2020"
      end
    end

    context "item is on loan" do
      let(:item) do
        Alma::BibItem.new("item_data" => { "awaiting_reshelving" => true })
      end

      it "displays 'Awaiting Reshelving' status" do
        expect(availability_status(item)).to eq "<span class=\"close-icon\"></span>Awaiting Reshelving"
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
           { "requested" => true ,
             "base_status" => { "value" => "0" },
             "process_type" => { "value" => "TRANSIT" }
           }
         )
      end

      it "displays process_type" do
        expect(unavailable_items(item)).to eq "<span class=\"close-icon\"></span>In transit"
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

  describe "#availability_alert(document)" do
    context "document availability contains nil values" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "AMBLER",
        "permanent_location" => "media",
        "current_library" => "AMBLER",
        "current_location" => "media",
        "call_number" => "DVD 13 A165",
        "availability" => nil,
        "holding_id" => "22237957750003811" }]
          }
        }

      it "returns true"  do
        expect(availability_alert(document)).to eq true
      end
    end

    context "document availability contains nil values" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "AMBLER",
        "permanent_location" => "media",
        "current_library" => "AMBLER",
        "current_location" => "media",
        "call_number" => "DVD 13 A165",
        "availability" => "<span class=\"check\"></span>Library Use Only",
        "holding_id" => "22237957750003811" }]
          }
        }

      it "returns true"  do
        expect(availability_alert(document)).to eq false
      end
    end

    context "document is an electronic resouce" do
      let(:document) { { "items_json_display" =>
        [{
          "item_pid" => "23237957740003811",
            "item_policy" => "5",
            "permanent_library" => "AMBLER",
            "permanent_location" => "media",
            "current_library" => "AMBLER",
            "current_location" => "media",
            "call_number" => "DVD 13 A165",
            "availability" => "<span class=\"check\"></span>Library Use Only",
            "holding_id" => "22237957750003811" }],
          "electronic_resource_display" =>
          [
            { "title" => "Access electronic resource.", "url" => "http://libproxy.temple.edu/login?url=http://www.aspresolver.com/aspresolver.asp?SHM2;1772483" },
            { "portfolio_id" => "77777", "title" => "Sample Name" },
          ]
          }
        }

      it "returns false"  do
        expect(availability_alert(document)).to eq false
      end
    end
  end

  describe "#render_alma_availability(document)" do
    let(:doc) { SolrDocument.new(bound_with_ids: ["foo"]) }
    let(:config) { CatalogController.blacklight_config }

    before do
      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config) { config }
      end
    end

    context "with bound_with_ids defined" do
      it "renders the bound_with_ids" do
        expect(helper.render_alma_availability(doc)).not_to be_nil
      end
    end

    context "with no bound with ids available" do
      let(:doc) { SolrDocument.new(bound_with_ids: nil) }

      it "does not render the bound_with_ids" do
        expect(helper.render_alma_availability(doc)).to be_nil
      end
    end

    context "without bound_with_ids configured" do
      let(:config) { PrimoCentralController.blacklight_config }

      it "does not render the bound_with_ids" do
        expect(helper.render_alma_availability(doc)).to be_nil
      end
    end
  end
end
