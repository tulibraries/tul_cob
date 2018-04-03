# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlmaDataHelper, type: :helper do
  describe "#availability_status(item)" do
    context "item base_status is 1" do
      let(:item) do
        { "item_data" =>
           { "base_status" =>
             { "value" => "1" }
           }
         }
      end

      it "displays available" do
        expect(availability_status(item)).to eq "Available"
      end
    end

    context "item base_status is 0" do
      let(:item) do
        { "item_data" =>
           { "base_status" =>
             { "value" => "0" }
           }
         }
      end

      it "displays available" do
        expect(availability_status(item)).to eq "Checked out or currently unavailable"
      end
    end
  end

  describe "#description(item)" do
    context "item includes description" do
      let(:item) do
        { "item_data" =>
           { "description" => "v. 1" }
         }
      end

      it "displays description" do
        expect(description(item)).to eq "Description: v. 1"
      end
    end

    context "item does NOT include description" do
      let(:item) do
        { "item_data" =>
           { "description" => "" }
         }
      end

      it "displays nothing" do
        expect(description(item)).to eq nil
      end
    end
  end

  describe "#public_note(item)" do
    context "item includes public note" do
      let(:item) do
        { "item_data" =>
           { "public_note" => "example" }
         }
      end

      it "displays note" do
        expect(public_note(item)).to eq "Note: example"
      end
    end

    context "item does NOT include public note" do
      let(:item) do
        { "item_data" =>
           { "public_note" => "" }
         }
      end

      it "displays nothing" do
        expect(public_note(item)).to eq nil
      end
    end
  end

  describe "#location_status(item)" do
    context "item is in temporary location" do
      let(:item) do
        { "holding_data" =>
           { "in_temp_location" => true,
             "temp_location" => "Temporary location",
             "temp_call_number" => "Temp call number"
            }
         }
      end

      it "displays temporary location and call number" do
        expect(location_status(item)).to eq "Temporary location - Temp call number"
      end
    end

    context "item is NOT in temporary location" do
      let(:item) do
        { "holding_data" =>
           { "in_temp_location" => false,
             "call_number" => "Perm call number"
           },
           "item_data" => {
             "location" => { "value" => "Permanent location" },
           }
         }
      end

      it "displays location and call number" do
        expect(location_status(item)).to eq "Permanent location - Perm call number"
      end
    end
  end

  describe "#library_status(item)" do
    context "item is in temporary library" do
      let(:item) do
        { "holding_data" =>
           { "in_temp_location" => true,
             "temp_library" => { "value" => "Temporary Library" },
            }
         }
      end

      it "displays temporary library" do
        expect(library_status(item)).to eq "Temporary Library"
      end
    end
  end

  describe "#alternative_call_number(item)" do
    context "item has an alternate call number" do
      let(:item) do
        { "item_data" =>
           { "alternative_call_number" => "alternate" }
         }
      end

      it "displays alternate call number" do
        expect(alternative_call_number(item)).to eq "(Also found under alternate)"
      end
    end
  end
end
