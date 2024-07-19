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
        expect(subject.message).to eq "<b>Your request has been submitted!</b> Your item will be available for pickup at Charles Library within 1-3 business days. We will notify you by email once it's ready."
      end
    end

    context "item to be delivered to Japan Campus Library" do
      let(:response) { Alma::BibRequest.submit(
        mms_id: "request_sent_from_bookbot", user_id: "user_id", request_type: "HOLD", pickup_location_type: "LIBRARY", pickup_location_library: "JAPAN"
      )}
      let(:pickup_location) { "JAPAN" }
      it "does not generate time estimate message" do
        expect(subject.message).to eq "<b>Your request has been submitted!</b> We will notify you by email once it's ready."
        expect(subject.delivery_estimate_message).to eq nil
      end
    end

  end
end

RSpec.describe RequestDeliveryEstimate, type: :model do

  subject { described_class.new(sent_from, pickup_location) }

  describe "delivery estimates" do

    context "item to be delivered from Ambler Campus Library to Charles Library" do
      let(:sent_from) { "AMBLER" }
      let(:pickup_location) { "MAIN" }
      it "generates time estimate" do
        expect(subject.duration).to eq "1-3 business days"
        expect(subject.message).to eq "Your item will be available for pickup at Charles Library within 1-3 business days. "
      end
    end

    context "item to be delivered within Charles Library (not ASRS)" do
      let(:sent_from) { "MAIN" }
      let(:pickup_location) { "MAIN" }
      it "generates time estimate" do
        expect(subject.duration).to eq "1-2 business days"
        expect(subject.message).to eq "Your item will be available for pickup at Charles Library within 1-2 business days. "
      end
    end

    context "item to be delivered from ASRS to Charles Library" do
      let(:sent_from) { "ASRS" }
      let(:pickup_location) { "MAIN" }
      it "generates time estimate" do
        expect(subject.duration).to eq "1 hour"
        expect(subject.message).to eq "If you placed the order during the library's normal operating hours, your item will be available for pickup at Charles Library within 1 hour. "
      end
    end

    context "no pickup location submitted in request (application to Digitization and Booking request currently, though also works for Holds)" do
      let(:sent_from) { nil }
      let(:pickup_location) { nil }
      it "does not generate time estimate" do
        expect(subject.duration).to eq nil
        expect(subject.message).to eq nil
      end
    end

  end

end
