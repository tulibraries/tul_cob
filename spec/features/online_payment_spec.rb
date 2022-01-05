# frozen_string_literal: true

require "rails_helper"
require "yaml"
include ApplicationHelper

RSpec.feature "Online Payments" do

  let(:user) { FactoryBot.create(:user) }

  before do
    allow(user).to receive(:alma) { alma }
    login_as(user, scope: :user)
  end

  after do
    logout
  end

  context "User does not have any fines" do
    let(:alma) { OpenStruct.new(total_fines: 0.0) }

    scenario "user goes to account page" do
      visit users_account_path

      expect(page).to_not have_link "Pay Online"
    end
  end

  context "User has fines but is not part proper group" do
    let(:alma) { OpenStruct.new(
      total_fines: 1.0,
      user_group: { "value" => "99" }
    ) }

    scenario "user goes to account page" do
      visit users_account_path

      expect(page).to_not have_link "Pay Online"
    end
  end

  context "User has fines and is part of proper group"  do
    let(:alma) { OpenStruct.new(
      total_fines: 1.0,
      user_group: { "value" => "2" }
    ) }

    scenario "user goes to account page" do
      visit users_account_path

      expect(page).to have_link "Pay Online"
    end
  end
end
