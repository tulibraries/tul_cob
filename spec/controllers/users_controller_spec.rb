# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersController, type: :controller do

  context "User logged in" do
    before(:all) do
      DatabaseCleaner.clean
      DatabaseCleaner.strategy = :truncation
      OmniAuth.config.test_mode = true
      user = FactoryBot.create :user
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

  describe "Impersonate user" do
    before :each do
      @original_state = Rails.env
    end

    after (:each) do
      Rails.env = @original_state
    end

    context "Test environment" do
      before :each do
        admin = FactoryBot.create :user_admin
        sign_in :user, admin
      end

      subject { get :index }

      context "Configured impersonator not allowed" do
        it "shows users page anyways" do
          expect(subject).to render_template(:index)
        end
      end

      context "Configured impersonator allowed" do
        it "shows users page" do
          expect(subject).to render_template("users/index")
        end
      end
    end

    context "Development environment" do
      before (:all) do
        Rails.env = "development"
      end

      subject { get :index }

      context "User Not Logged In" do

        context "Configured impersonator not allowed" do
          it "shows users page" do
            expect(subject).to redirect_to('http://test.host/')
          end
        end
      end

      context "User Logged In" do
        before :each do
          admin = FactoryBot.create :user_admin
          sign_in :user, admin
        end

        context "Configured impersonator not allowed" do
          it "shows users page" do
            expect(subject).to render_template(:index)
          end
        end

        context "Configured impersonator allowed" do
          it "shows users page" do
            expect(subject).to render_template(:index)
          end
        end
      end
    end

    context "Production environment" do
      before :each do
        Rails.env = "production"
      end

      subject { get :index }

      context "User Logged In" do
        before :each do
          admin = FactoryBot.create :user_admin
          sign_in :user, admin
        end

        context "Configured impersonator not allowed" do
          before :each do
            Rails.configuration.allow_impersonator = false
          end

          it "redirects to root" do
            expect(subject).to redirect_to('http://test.host/')
          end
        end

        context "Configured impersonator allowed" do
          before :each do
            Rails.configuration.allow_impersonator = true
          end

          it "shows users page" do
            expect(subject).to render_template(:index)
          end
        end
      end

      context "No User Logged In" do

        context "Configured impersonator not allowed" do
          before :each do
            Rails.configuration.allow_impersonator = false
          end

          it "redirects to root" do
            expect(subject).to redirect_to('http://test.host/')
          end
        end

        context "Configured impersonator allowed" do
          before :each do
            Rails.configuration.allow_impersonator = true
          end

          it "redirects to root" do
            expect(subject).to redirect_to('http://test.host/')
          end
        end
      end
    end
  end

end
