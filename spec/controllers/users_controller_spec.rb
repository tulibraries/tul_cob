require 'rails_helper'

RSpec.describe UsersController, type: :controller do

  context "User logged in" do
    before(:all) do
      DatabaseCleaner.clean
      DatabaseCleaner.strategy = :truncation
      OmniAuth.config.test_mode = true
      user = FactoryGirl.create :user
      OmniAuth.config.mock_auth[:alma] = OmniAuth::AuthHash.new({
        email: user.email,
        created_at: user.created_at,
        updated_at: user.updated_at,
        guest: user.guest,
        alma_id: user.alma_id,
        provider: user.provider,
        uid: user.uid
      })
    end

    after :all do
      DatabaseCleaner.clean
    end

    context "User had transactions" do
      describe "GET #loans" do
        xit "returns http success" do
          get :loans
          expect(response).to have_http_status(:success)
        end
      end

      describe "GET #holds" do
        xit "returns http success" do
          get :holds
          expect(response).to have_http_status(:success)
        end
      end

      describe "GET #fines" do
        xit "returns http success" do
          get :fines
          expect(response).to have_http_status(:success)
        end
      end
    end

    context "User has no transactions" do
      it "shows no items borrowed"
      it "shows no item hold requests"
      it "shows no fines"
    end
  end

  context "User not logged in" do
    it "redirects loans list to login"
    it "redirects holds list to login"
    it "redirects fines list to login"
  end

  describe "GET #renew" do
    xit "returns http success" do
      get :renew
      expect(response).to have_http_status(:success)
    end
  end

end
