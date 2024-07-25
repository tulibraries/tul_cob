# frozen_string_literal: true

require "rails_helper"

RSpec.describe RequestConfirmation, type: :model do

  subject { described_class.new(response, pickup_location) }

  describe "confirmation message" do

    context "item to be delivered from Ambler Campus Library to Charles Library" do
      let(:response) { Alma::BibRequest.submit(
        mms_id: "request_sent_from_ambler", user_id: "user_id", request_type: "HOLD", pickup_location_type: "LIBRARY", pickup_location_library: "MAIN"
      )}
      let(:pickup_location) { "MAIN" }
      it "generates time estimate" do
        expect(subject.message).to eq "<b>Your request has been submitted!</b> <br>Your item will be available for pickup at Charles Library within 1-3 business days. We will notify you by email once it's ready."
      end
    end

    context "item to be delivered to Japan Campus Library" do
      let(:response) { Alma::BibRequest.submit(
        mms_id: "request_sent_from_bookbot", user_id: "user_id", request_type: "HOLD", pickup_location_type: "LIBRARY", pickup_location_library: "JAPAN"
      )}
      let(:pickup_location) { "JAPAN" }
      it "does not generate delivery estimate message" do
        expect(subject.message).to eq "<b>Your request has been submitted!</b> <br>We will notify you by email once it's ready."
        expect(subject.delivery_estimate_message).to eq nil
      end
    end

  end
end
