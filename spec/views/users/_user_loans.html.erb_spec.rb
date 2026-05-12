# frozen_string_literal: true

require "rails_helper"
require "time"

RSpec.describe "users/_loans_details.html.erb", type: :view do
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
      loans = double("Loan Set", all: [renewable_loan])
      render partial: "users/loans_details", locals: { loans: }
      expect(rendered).to_not have_css('td.renewal-check span.glyphicon-exclamation-sign[title="unable to renew"]')
    end

    it "doesn't show exclamation point in renewal column" do
      loans = double("Loan Set", all: [renewable_loan_without_flag])
      render partial: "users/loans_details", locals: { loans: }
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
      loans = double("Loan Set", all: [nonrenewable_loan])
      render partial: "users/loans_details", locals: { loans: }
      expect(rendered).to have_css('td.renewal-check i.fa-exclamation-circle[title="unable to renew"]')
    end
  end

  context "when the user has more than 100 loans" do
    it "renders loans beyond the first 100 returned by the loan set" do
      all_loans = Array.new(101) do |index|
        loan_number = index + 1

        OpenStruct.new(
          loan_id: "loan-#{loan_number}",
          title: "Loan #{loan_number}",
          due_date: (Time.now + one_day).iso8601,
          item_barcode: "barcode-#{loan_number}",
          call_number: "Call #{loan_number}",
          renewable: true,
          loan_status: "Active",
          renewable?: true,
          overdue?: false
        )
      end

      loans = double("Loan Set")

      allow(loans).to receive(:all).and_return(all_loans)
      allow(loans).to receive(:present?).and_return(true)
      allow(loans).to receive(:each_with_index) do |&block|
        all_loans.first(100).each_with_index(&block)
      end

      render partial: "users/loans_details", locals: { loans: loans }

      expect(rendered).to have_field("loan_id_loan-101")
      expect(rendered).to have_css("input[name='loan_ids[]']", count: 101)
    end
  end
end
