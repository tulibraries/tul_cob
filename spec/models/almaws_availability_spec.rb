# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlmawsAvailability, type: :model do

  subject { described_class.new(item) }

  describe "Availability::TemporaryStatus" do

    context "item is in temporary MAIN storage" do
      let(:item) do
        Alma::BibItem.new(
          "holding_data" => { "in_temp_location" => true, "temp_location" => { "value" => "storage" } },
          "item_data" => { "base_status" => { "value" => "1" } }
          )
      end

      it "displays Temporarily unavailable" do
        expect(subject.status).to eq("Temporarily unavailable")
        expect(subject.icon).to eq "close-icon"
      end
    end

  end

  describe "Availability::Available" do

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
        expect(subject.status).to eq "Available"
        expect(subject.icon).to eq "check"

      end
    end

    context "item base_status is 1 and item is requested" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "base_status" =>
             { "value" => "1" },
             "requested" => true,
           }
         )
      end

      it "displays requested" do
        expect(subject.status).to eq "Available (Pending Request)"
      end
    end

    context "item is awaiting reshelving" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
          { "base_status" =>
            { "value" => "1" },
            "awaiting_reshelving" => true
          }
        )
      end

      it "displays 'Awaiting Reshelving' status" do
        expect(subject.status).to eq "Awaiting Reshelving"
      end
    end

    context "Non-circulating policy" do
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
        expect(subject.tul_non_circulating?).to eq true
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
        expect(subject.tul_non_circulating?).to eq true
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
        expect(subject.tul_non_circulating?).to eq true
      end
    end
  end

  describe "Availability::Unavailable" do

    context "item base_status is 0 and has process type" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "base_status" =>
             { "value" => "0" },
             "process_type" => { "value" => "ILL" }
           }
         )
      end

      it "displays unavailable" do
        expect(subject.status).to eq "At another institution"
        expect(subject.icon).to eq "close-icon"
      end
    end

    context "item base_status is 0 and has a different process type" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "requested" => true ,
             "base_status" => { "value" => "0" },
             "process_type" => { "value" => "TRANSIT" }
           }
         )
      end

      it "displays process_type" do
        expect(subject.status).to eq "In transit"
        expect(subject.icon).to eq "close-icon"
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
        expect(subject.status).to eq "Checked out, due 09/01/2020"
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
        expect(subject.status).to eq "Checked out or currently unavailable"
      end
    end

  end

  describe "Availability::Base" do

    context "item has no process_type" do
      let(:item) do
        Alma::BibItem.new("item_data" =>
           { "base_status" =>
             { "value" => "0" }
           }
         )
      end

      it "displays html" do
        expect(subject.status).to eq "Checked out or currently unavailable"
        expect(subject.icon).to eq "close-icon"
      end
    end

  end
end
