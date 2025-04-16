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
        rendered_message = Capybara::Node::Simple.new(subject.message)
        expect(rendered_message).to have_content I18n.t("requests.default_success")
        expect(rendered_message).to have_content subject.delivery_estimate_message
        expect(rendered_message).to have_content I18n.t("requests.request_status_message")
      end
    end

    context "item to be delivered to Japan Campus Library" do
      let(:response) { Alma::BibRequest.submit(
        mms_id: "request_sent_from_bookbot", user_id: "user_id", request_type: "HOLD", pickup_location_type: "LIBRARY", pickup_location_library: "JAPAN"
      )}
      let(:pickup_location) { "JAPAN" }
      it "does not generate delivery estimate message" do
        rendered_message = Capybara::Node::Simple.new(subject.message)
        expect(rendered_message).to have_content I18n.t("requests.default_success")
        expect(rendered_message).to have_content I18n.t("requests.request_status_message")
        expect(subject.delivery_estimate_message).to eq nil
      end
    end

  end
end
