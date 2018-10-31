# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlmawsHelper, type: :helper do
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
      let(:response) { OpenStruct.new(body: json) }
      let(:request_options) { Alma::RequestOptions.new(response) }

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
      let(:response) { OpenStruct.new(body: json) }
      let(:request_options) { Alma::RequestOptions.new(response) }

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

      let(:response) { OpenStruct.new(body: json) }
      let(:request_options) { Alma::RequestOptions.new(response) }

      it "is false" do
        expect(helper.only_one_option_allowed(request_options)).to be false
      end
    end
  end
end
