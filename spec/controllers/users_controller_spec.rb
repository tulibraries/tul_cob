# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersController, type: :controller do

  context "User logged in" do
    before(:all) do
      DatabaseCleaner.clean
      DatabaseCleaner.strategy = :truncation
      OmniAuth.config.test_mode = true
      user = FactoryBot.build_stubbed :user
      OmniAuth.config.mock_auth[:alma] = OmniAuth::AuthHash.new(email: user.email,
        created_at: user.created_at,
        updated_at: user.updated_at,
        guest: user.guest,
        alma_id: user.alma_id,
        provider: user.provider,
        uid: user.uid)
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
        render_views

        xit "returns http success" do
          get :holds
          expect(response).to have_http_status(:success)
        end

        it "renders the expiry_date when present" do
          request_set = instance_double(Alma::RequestSet)
          hold_request = Alma::UserRequest.new({ "title" => "hold it", "request_status" => "pending", "expiry_date" => "2017-06-20Z" })
          allow(request_set).to receive(:each_with_index).and_yield(hold_request, 1)
          user = instance_double(User)
          allow(user).to receive(:holds).and_return(request_set)
          allow(request_set).to receive(:success?).and_return(true)
          allow(controller).to receive(:current_user).and_return(user)
          get :holds
          expect(response).to have_http_status 200
          expect(response.body).to include "06/19/2017"
        end

        it "can manage when the hold data object doesn't have an expiry_date" do
          request_set = instance_double(Alma::RequestSet)
          hold_request = Alma::UserRequest.new({ "title" => "hold it", "request_status" => "pending" })
          allow(request_set).to receive(:each_with_index).and_yield(hold_request, 1)
          user = instance_double(User)
          allow(user).to receive(:holds).and_return(request_set)
          allow(request_set).to receive(:success?).and_return(true)
          allow(controller).to receive(:current_user).and_return(user)
          get :holds
          expect(response).to have_http_status 200
          expect(response.body).to include "requests from the Special Collections Research Center"
        end
      end

      describe "GET #fines" do
        xit "returns http success" do
          get :fines
          expect(response).to have_http_status(:success)
        end
      end

      describe "GET #account" do
        before do
          DatabaseCleaner.clean
          DatabaseCleaner.strategy = :truncation
          user = FactoryBot.create :user
          sign_in user, scope: :user
        end

        it "has no-cache headers for account" do
          get :account
          expect(response.headers["Cache-Control"]).to eq("no-cache, no-store")
          expect(response.headers["Pragma"]).to eq("no-cache")
          expect(response.headers["Expires"]).to eq("Fri, 01 Jan 1990 00:00:00 GMT")
        end

        describe "before_action get_manifold_alerts" do
          it "sets @manifold_alerts_thread" do
            get :account
            expect(controller.instance_variable_get("@manifold_alerts_thread")).to be_kind_of(Thread)
          end
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

  describe "GET #renew_multi" do
    xit "returns http success" do
      get :renew_multi
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #renew_all_loans" do
    xit "returns http success" do
      get :renew_all_loans
      expect(response).to have_http_status(:success)
    end
  end

end
