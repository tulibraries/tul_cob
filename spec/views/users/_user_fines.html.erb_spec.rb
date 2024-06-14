# frozen_string_literal: true

require "rails_helper"

RSpec.describe "users/_loans_fines.html.erb", type: :view do
  before :each do
    @user = FactoryBot.build(:user)
  end

  context "no title for fee" do
    let(:fee_no_title) {
      OpenStruct.new(
        id: "12345",
        type: { "value" => "CUSTOMER_DEFINED_02", "desc" => "Makerspace Fee" },
        balance: 0.01
      )
    }

    it "doesn't render title in view" do
      fines = [fee_no_title]
      render partial: "users/fines_details", locals: { fines: }
      expect(rendered).to have_selector("td:empty")
    end
  end

  context "item title for fee" do
    let(:fee_title) {
      OpenStruct.new(
        id: "67890",
        title: "Test",
        type: { "value" => "OVERDUEFINE", "desc" => "Overdue fine" },
        balance: 0.01
      )
    }

    it "render title in view" do
      fines = [fee_title]
      render partial: "users/fines_details", locals: { fines: }
      expect(rendered).to have_selector("td", text: "Test")
    end
  end
end
