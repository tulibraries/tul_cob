# frozen_string_literal: true

require "rails_helper"

RSpec.describe "almaws/_hold_request_form.html.erb", type: :view do
  before do
    assign(:mms_id, "991030224789703811")
    assign(:holding_id, nil)
    assign(:item_pid, nil)
    assign(:user_id, "915229677")
    assign(:request_level, request_level)
    assign(:equipment, [])
    assign(:material_types, [])
    assign(:description, [])
    assign(:item_level_locations, {})
    assign(:items, items)

    allow(view).to receive(:available_asrs_items).and_return(available_asrs_items)
  end

  let(:request_level) { "bib" }
  let(:items) do
    [
      instance_double(
        "AlmaItem",
        library: "MAIN",
        item_data: {
          "library" => { "desc" => "Charles Library" },
          "location" => { "desc" => "Stacks" }
        }
      )
    ]
  end
  let(:available_asrs_items) { [] }
  let(:pickup_locations) do
    [
      { "MAIN" => "Charles Library" },
      { "ASRS" => "Charles Library - BookBot" },
      { "JAPAN" => "Japan Campus Library" }
    ]
  end

  context "pickup locations" do
    it "hides ASRS when no ASRS items are available" do
      assign(:pickup_locations, pickup_locations)

      render partial: "almaws/hold_request_form"

      doc = Nokogiri::HTML(rendered)
      options = doc.css('select[name="hold_pickup_location"] option').map { |o| o["value"] }.compact

      expect(options).to include("MAIN", "JAPAN")
      expect(options).not_to include("ASRS")
    end

    context "when ASRS items are available" do
      let(:available_asrs_items) { [instance_double("AlmaItem")] }

      it "shows ASRS" do
        assign(:pickup_locations, pickup_locations)

        render partial: "almaws/hold_request_form"

        doc = Nokogiri::HTML(rendered)
        options = doc.css('select[name="hold_pickup_location"] option').map { |o| o["value"] }.compact

        expect(options).to include("MAIN", "JAPAN", "ASRS")
      end
    end
  end
end
