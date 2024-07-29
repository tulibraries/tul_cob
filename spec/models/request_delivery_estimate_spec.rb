# frozen_string_literal: true

require "rails_helper"

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

      context "item to be delivered to Japan Campus Library" do
        let(:sent_from) { "JAPAN" }
        let(:pickup_location) { "JAPAN" }
        it "does not generate time estimate" do
          expect(subject.duration).to eq nil
          expect(subject.message).to eq nil
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
