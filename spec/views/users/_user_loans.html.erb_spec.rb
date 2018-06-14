# frozen_string_literal: true

require "rails_helper"
require "time"

RSpec.describe "users/_user_loans.html.erb", :focus, type: :view do
  before :each do
    @user = FactoryBot.build(:user)
  end

  let(:one_day) { 24 * 3600 }

  context "Renewable" do
    let(:renewable_loan) {
      OpenStruct.new(
        loan_id: "12345",
        title: "History",
        due_date: (Time.now + one_day).iso8601, # tomorrow
        item_barcode: "000237055710000121",
        call_number: "AA123",
        renewable: true,
        loan_status: "Active",
        renewable?: true
      )
    }

    let(:renewable_loan_without_flag) {
      OpenStruct.new(
        loan_id: "12345",
        title: "History",
        due_date: (Time.now + one_day).iso8601, # tomorrow
        item_barcode: "000237055710000121",
        call_number: "AA123",
        loan_status: "Active",
        renewable?: true
      )
    }

    it "doesn't show exclamation point in renewal column" do
      allow(@user).to receive(:loans).and_return([renewable_loan])

      render partial: "users/user_loans"
      expect(rendered).to_not have_css('td.renewal-check span.glyphicon-exclamation-sign[title="unable to renew"]')
    end

    it "doesn't show exclamation point in renewal column" do
      allow(@user).to receive(:loans).and_return([renewable_loan_without_flag])

      render partial: "users/user_loans"
      expect(rendered).to_not have_css('td.renewal-check span.glyphicon-exclamation-sign[title="unable to renew"]')
    end
  end

  context "Non-Renewable" do
    let(:nonrenewable_loan) {
      OpenStruct.new(
        loan_id: "12345",
        title: "History",
        due_date: (Time.now + one_day).iso8601, # tomorrow
        item_barcode: "000237055710000121",
        call_number: "AA123",
        renewable: false,
        loan_status: "Active",
        renewable?: false
      )
    }

    it "shows exclamation point in renewal column" do
      allow(@user).to receive(:loans).and_return([nonrenewable_loan])

      render partial: "users/user_loans"
      expect(rendered).to have_css('td.renewal-check span.glyphicon-exclamation-sign[title="unable to renew"]')
    end
  end
end
