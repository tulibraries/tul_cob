# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlmawsHelper, type: :helper do
  let(:json) { {}.to_json }
  let(:request_options) { Alma::RequestOptions.get("foo") }
  let(:items_list) { Alma::BibItem.find("merge_document_and_api") }

  before do
    helper.instance_variable_set(:@equipment, [])
    helper.instance_variable_set(:@material_types, [])
    helper.instance_variable_set("@items", items_list)
    stub_request(:any, /request-options/).
      and_return(headers: { "Content-Type" => "application/json" },
                 body: json,
                 status: 200)
  end

  describe "#hold_allowed_partial" do
    let(:json) {
      { request_option:
        [{
        "type" => { "value" => "HOLD", "desc" => "Hold" },
        "request_url" => "https://api-na.hosted.exlibrisgroup.com/almaws/v1/requests/"
        }]
      }.to_json
    }

    context "hold can be placed on an item" do
      it "renders the hold partial" do
        expect(helper.hold_allowed_partial(request_options)).not_to be_nil
      end
    end

    context "hold cannot be placed on an item" do
      let(:json) {
        { request_option:
          [{
          "type" => { "value" => "BOOKING", "desc" => "Booking" },
          "request_url" => "https://api-na.hosted.exlibrisgroup.com/almaws/v1/requests/"
          }]
        }.to_json
      }

      it "does not render the hold partial" do
        expect(helper.hold_allowed_partial(request_options)).to be_nil
      end
    end
  end

  describe "#asrs_allowed_partial" do
    let(:json) {
      { request_option:
        [{
        "type" => { "value" => "HOLD", "desc" => "Hold" },
        "request_url" => "https://api-na.hosted.exlibrisgroup.com/almaws/v1/requests/"
        }]
      }.to_json
    }

    context "asrs request can be placed on an item" do
      let(:item) do
       Alma::BibItem.new(
         "holding_data" => {
           "holding_id" => "foo",
         },
         "item_data" =>
         { "base_status" =>
           { "value" => "1" },
             "policy" =>
           { "desc" => "Non-circulating" },
             "requested" => false,
             "library" => {
               "value" => "ASRS",
               "desc" => "ASRS"
             },
             "location" => {
               "value" => "stacks",
               "desc" => "Stacks"
             },
             "physical_material_type" => {
               "value" => "BOOK",
               "desc" => "book"
             },
         }
        )
     end

      it "renders the hold partial" do
        allow(helper).to receive(:available_asrs_items) { [item] }
        expect(helper.asrs_allowed_partial(request_options)).not_to be_nil
      end
    end

    context "asrs request cannot be placed on an item" do
      let(:json) {
        { request_option:
          [{
          "type" => { "value" => "HOLD", "desc" => "Hold" },
          "request_url" => "https://api-na.hosted.exlibrisgroup.com/almaws/v1/requests/"
          }]
        }.to_json
      }

      it "does not render the hold partial" do
        allow(helper).to receive(:available_asrs_items) { [] }
        expect(helper.asrs_allowed_partial(request_options)).to be_nil
      end
    end
  end

  describe "#digitization_allowed_partial" do
    let(:json) {
      { request_option:
        [{
        "type" => { "value" => "DIGITIZATION", "desc" => "Digitization" },
        "request_url" => "https://api-na.hosted.exlibrisgroup.com/almaws/v1/requests/"
        }]
      }.to_json
    }

    context "An item can be requested to be scanned" do
      it "renders the digitization_allowed partial" do
        expect(helper.digitization_allowed_partial(request_options)).not_to be_nil
      end
    end

    context "An item cannot be requested to be scanned" do
      let(:json) {
        { request_option:
          [{
          "type" => { "value" => "BOOKING", "desc" => "Booking" },
          "request_url" => "https://api-na.hosted.exlibrisgroup.com/almaws/v1/requests/"
          }]
        }.to_json
      }

      it "does not render the digitization_allowed partial" do
        expect(helper.digitization_allowed_partial(request_options)).to be_nil
      end
    end
  end

  describe "#booking_allowed_partial" do
    let(:json) {
      { request_option:
        [{
        "type" => { "value" => "BOOKING", "desc" => "Booking" },
        "request_url" => "https://api-na.hosted.exlibrisgroup.com/almaws/v1/requests/"
        }]
      }.to_json
    }

    context "booking can be placed on an item" do
      it "renders the booking_allowed partial" do
        expect(helper.booking_allowed_partial(request_options)).not_to be_nil
      end
    end

    before do
      helper.instance_variable_set(:@booking_location, [])
      helper.instance_variable_set(:@material_types, [])
    end

    context "booking cannot be placed on an item" do
      let(:json) {
        { request_option:
          [{
          "type" => { "value" => "HOLD", "desc" => "Hold" },
          "request_url" => "https://api-na.hosted.exlibrisgroup.com/almaws/v1/requests/"
          }]
        }.to_json
      }

      it "does not render the booking_allowed partial" do
        expect(helper.booking_allowed_partial(request_options)).to be_nil
      end
    end
  end

  describe "#resource_sharing_broker_allowed_partial" do
    let(:json) {
      { request_option:
        [{
        "type" => { "value" => "RS_BROKER", "desc" => "Resource Sharing Broker" },
        "request_url" => "https://e-zborrow.relais-host.com/user/login.html?group=patron&LS=TEMPLE&dest=discovery&PI=915602377&RK=915602377&rft.stitle=A+thin+bright+line+%2F&rft.pub=The+University+of+Wisconsin+Press%2C&rft.place=Madison%2C+Wisconsin+%3A&rft.isbn=0299309304&rft.btitle=A+thin+bright+line+%2F&rft.genre=book&rft.normalized_isbn=9780299309305&rft.oclcnum=946770187&rft.mms_id=991028550499703811&rft.object_type=BOOK&rft.publisher=The+University+of+Wisconsin+Press%2C&rft.au=Bledsoe%2C+Lucy+Jane%2C+author.&rft.pubdate=%5B2016%5D&rft.title=A+thin+bright+line+%2F"
        }]
      }.to_json
    }
    let(:books) { "BOOK" }

    context "item can be requested through ez-borrow" do
      it "renders the resource_sharing_broker partial" do
        expect(helper.resource_sharing_broker_allowed_partial(request_options, books)).not_to be_nil
      end
    end

    context "item cannot be requested through ez-borrow" do
      let(:json) {
        { request_option:
          [{
          "type" => { "value" => "BOOKING", "desc" => "Booking" },
          "request_url" => "https://e-zborrow.relais-host.com/user/login.html?group=patron&LS=TEMPLE&dest=discovery&PI=915602377&RK=915602377&rft.stitle=A+thin+bright+line+%2F&rft.pub=The+University+of+Wisconsin+Press%2C&rft.place=Madison%2C+Wisconsin+%3A&rft.isbn=0299309304&rft.btitle=A+thin+bright+line+%2F&rft.genre=book&rft.normalized_isbn=9780299309305&rft.oclcnum=946770187&rft.mms_id=991028550499703811&rft.object_type=BOOK&rft.publisher=The+University+of+Wisconsin+Press%2C&rft.au=Bledsoe%2C+Lucy+Jane%2C+author.&rft.pubdate=%5B2016%5D&rft.title=A+thin+bright+line+%2F"
          }]
        }.to_json
      }

      it "does not render the hold partial" do
        expect(helper.resource_sharing_broker_allowed_partial(request_options, books)).to be_nil
      end
    end
  end

  describe "#no_temple_request_options_available" do
    let(:json) {
      { request_option:
        [{
        "type" => { "value" => "RS_BROKER", "desc" => "Resource Sharing Broker" },
        "request_url" => "https://e-zborrow.relais-host.com/user/login.html?group=patron&LS=TEMPLE&dest=discovery&PI=915602377&RK=915602377&rft.stitle=A+thin+bright+line+%2F&rft.pub=The+University+of+Wisconsin+Press%2C&rft.place=Madison%2C+Wisconsin+%3A&rft.isbn=0299309304&rft.btitle=A+thin+bright+line+%2F&rft.genre=book&rft.normalized_isbn=9780299309305&rft.oclcnum=946770187&rft.mms_id=991028550499703811&rft.object_type=BOOK&rft.publisher=The+University+of+Wisconsin+Press%2C&rft.au=Bledsoe%2C+Lucy+Jane%2C+author.&rft.pubdate=%5B2016%5D&rft.title=A+thin+bright+line+%2F"
        }]
      }.to_json
    }
    let(:books) { "BOOK" }

    context "there are no Temple request options available" do
      it "renders the resource_sharing_broker partial" do
        expect(helper.resource_sharing_broker_allowed_partial(request_options, books)).not_to be_nil
      end
    end

    context "Temple request options are available" do
      let(:json) {
        { request_option:
          [{
          "type" => { "value" => "BOOKING", "desc" => "Booking" },
          "request_url" => "https://api-na.hosted.exlibrisgroup.com/almaws/v1/requests/"
          }]
        }.to_json
      }

      it "does not render the hold partial" do
        expect(helper.resource_sharing_broker_allowed_partial(request_options, books)).to be_nil
      end
    end
  end

  describe "#only_one_option_allowed(request_options)" do
    context "only a hold is allowed" do
      let(:json) {
        { request_option:
          [{
          "type" => { "value" => "HOLD", "desc" => "Hold" },
          "request_url" => "https://api-na.hosted.exlibrisgroup.com/almaws/v1/requests/"
          }]
        }.to_json
      }

      it "is true" do
        expect(helper.only_one_option_allowed(request_options)).to be true
      end
    end

    context "only a booking is allowed" do
      let(:json) {
        { request_option:
          [{
          "type" => { "value" => "BOOKING", "desc" => "Booking" },
          "request_url" => "https://api-na.hosted.exlibrisgroup.com/almaws/v1/requests/"
          }]
        }.to_json
      }

      it "is true" do
        expect(helper.only_one_option_allowed(request_options)).to be true
      end
    end

    context "both a hold and a booking are allowed" do
      let(:json) {
        {
          "request_option": [
            {
              "type": {
                "value": "HOLD",
                "desc": "Hold"
              },
              "request_url": "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/915602377/requests/"
            },
            {
              "type": {
                "value": "BOOKING",
                "desc": "Booking"
              },
              "request_url": "https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/915602377/requests/"
            },
            {
              "type": {
                "value": "PURCHASE",
                "desc": "Purchase"
              }
            }
          ]
        }.to_json
      }

      it "is false" do
        expect(helper.only_one_option_allowed(request_options)).to be false
      end
    end
  end

  describe "#is_asrs_item?(item)" do
    context "item is located in ASRS" do
     let(:item) do
       Alma::BibItem.new("item_data" =>
          { "base_status" =>
            { "value" => "1" },
            "policy" =>
            { "desc" => "Non-circulating" },
            "requested" => false,
            "library" => {
                   "value" => "ASRS",
                   "desc" => "ASRS"
             },
             "location" => {
                   "value" => "ASRS",
                   "desc" => "Automated Storage System"
             },
             "physical_material_type" => {
               "value" => "BOOK",
               "desc" => "book"
             },
          }
        )
     end

     it "returns true" do
       expect(helper.is_asrs_item?(item)).to be true
     end
   end

    context "item is NOT located in ASRS" do
     let(:item) do
       Alma::BibItem.new("item_data" =>
          { "base_status" =>
            { "value" => "1" },
            "policy" =>
            { "desc" => "Non-circulating" },
            "requested" => false,
            "library" => {
                   "value" => "AMBLER",
                   "desc" => "Ambler"
             },
             "location" => {
                   "value" => "stacks",
                   "desc" => "Stacks"
             },
          }
        )
     end

     it "returns true" do
       expect(helper.is_asrs_item?(item)).to be false
     end
   end
  end
end
