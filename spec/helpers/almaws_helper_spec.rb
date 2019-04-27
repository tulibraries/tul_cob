# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlmawsHelper, type: :helper do
  let(:json) { {}.to_json }
  let(:request_options) { Alma::RequestOptions.get("foo") }

  before do
    helper.instance_variable_set(:@equipment, [])
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
end
