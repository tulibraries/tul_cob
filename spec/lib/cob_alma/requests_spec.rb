# frozen_string_literal: true

require "rails_helper"

RSpec.describe CobAlma::Requests do

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
