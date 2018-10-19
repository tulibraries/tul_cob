# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlmawsHelper, type: :helper do
  describe "#hold_allowed_partial" do
    let(:json) {
      { request_option:
        [{
        "type" => { "value" => "HOLD", "desc" => "Hold" },
        "request_url" => "https://api-na.hosted.exlibrisgroup.com/almaws/v1/requests/"
        }]
      }.to_json
    }
    let(:response) { OpenStruct.new(body: json) }
    let(:request_options) { Alma::RequestOptions.new(response) }

    before do
      helper.instance_variable_set(:@equipment, [])
    end

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
    let(:response) { OpenStruct.new(body: json) }
    let(:request_options) { Alma::RequestOptions.new(response) }

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
    let(:response) { OpenStruct.new(body: json) }
    let(:request_options) { Alma::RequestOptions.new(response) }

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
        "request_url" => "https://api-na.hosted.exlibrisgroup.com/almaws/v1/requests/"
        }]
      }.to_json
    }
    let(:response) { OpenStruct.new(body: json) }
    let(:request_options) { Alma::RequestOptions.new(response) }
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
          "request_url" => "https://api-na.hosted.exlibrisgroup.com/almaws/v1/requests/"
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
        "request_url" => "https://api-na.hosted.exlibrisgroup.com/almaws/v1/requests/"
        }]
      }.to_json
    }
    let(:response) { OpenStruct.new(body: json) }
    let(:request_options) { Alma::RequestOptions.new(response) }
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
end
