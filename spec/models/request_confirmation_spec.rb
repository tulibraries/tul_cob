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
        expect(subject.message).to eq "Request submitted! Your item will be available for pickup at Charles Library in approximately 1-3 business days. You will receive an email notification when the item is ready."
      end
    end

  end

  describe "delivery estimates" do

    context "item to be delivered from Ambler Campus Library to Charles Library" do
      let(:response) { Alma::BibRequest.submit(
        mms_id: "request_sent_from_ambler", user_id: "user_id", request_type: "HOLD", pickup_location_type: "LIBRARY", pickup_location_library: "MAIN"
      )}
      let(:pickup_location) { "MAIN" }
      it "generates time estimate" do
        expect(subject.delivery_estimate).to eq "1-3 business days"
        expect(subject.delivery_estimate?).to eq true
      end
    end

    context "item to be delivered within Charles Library (not ASRS)" do
      let(:response) { Alma::BibRequest.submit(
        mms_id: "request_sent_from_main", user_id: "user_id", request_type: "HOLD", pickup_location_type: "LIBRARY", pickup_location_library: "MAIN"
      )}
      let(:pickup_location) { "MAIN" }
      it "generates time estimate" do
        expect(subject.delivery_estimate).to eq "1-2 business days"
        expect(subject.delivery_estimate?).to eq true
      end
    end

    context "item to be delivered from ASRS to Charles Library" do
      let(:response) { Alma::BibRequest.submit(
        mms_id: "request_sent_from_bookbot", user_id: "user_id", request_type: "HOLD", pickup_location_type: "LIBRARY", pickup_location_library: "MAIN"
      )}
      let(:pickup_location) { "MAIN" }
      it "generates time estimate" do
        expect(subject.delivery_estimate).to eq "1 hour, delivered from the Charles Library BookBot when open"
        expect(subject.delivery_estimate?).to eq true
      end
    end

    context "item to be delivered with Japan Campus Library" do
      let(:response) { Alma::BibRequest.submit(
        mms_id: "request_sent_from_bookbot", user_id: "user_id", request_type: "HOLD", pickup_location_type: "LIBRARY", pickup_location_library: "JAPAN"
      )}
      let(:pickup_location) { "JAPAN" }
      it "does not generate time estimate" do
        expect(subject.delivery_estimate).to eq nil
        expect(subject.delivery_estimate?).to eq false
        expect(subject.delivery_estimate_message).to eq ""
      end
    end

    context "no pickup location submitted in request (application to Digitization and Booking request currently, though also works for Holds)" do
      let(:response) { Alma::BibRequest.submit(
        mms_id: "request_sent_from_ambler", user_id: "user_id", request_type: "HOLD", pickup_location_type: "LIBRARY", pickup_location_library: "MAIN"
      )}
      it "does not generate time estimate" do
        expect(subject.delivery_estimate).to eq nil
        expect(subject.delivery_estimate?).to eq false
        expect(subject.delivery_estimate_message).to eq ""
      end
    end

  end

end
