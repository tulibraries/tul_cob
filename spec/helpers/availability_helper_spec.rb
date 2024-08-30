# frozen_string_literal: true

require "rails_helper"

RSpec.describe AvailabilityHelper, type: :helper do
  describe "#availability_status_display(item)" do

    context "availability status and icon" do
      let(:item) { { "availability" => "Available", "icon" => "check" } }

      it "renders availability status display" do
        expect(availability_status_display(item)).to eq "<span class=\"check\"></span>Available"
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
