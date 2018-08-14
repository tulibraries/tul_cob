# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlmawsController, type: :controller do
  before(:all) do
    DatabaseCleaner.clean
    DatabaseCleaner.strategy = :truncation
    OmniAuth.config.test_mode = true
    OmniAuth.config.test_mode = true
    @user = FactoryBot.create :user
    OmniAuth.config.mock_auth[:alma] = OmniAuth::AuthHash.new(email: @user.email,
      created_at: @user.created_at,
      updated_at: @user.updated_at,
      guest: @user.guest,
      alma_id: @user.alma_id,
      provider: @user.provider,
      uid: @user.uid)
  end

  describe "GET #item action" do

    let(:params) { {params: {mms_id: 123}} }

    context 'anonymous user' do
      it 'does not redirect to login page' do
        get(:item, params)
        expect(response).not_to redirect_to new_user_session_url
      end
    end
  end

  describe "GET #request_options action" do

    let(:params) { {params: {mms_id: 123, pickup_location: "some,place" , request_level: 'bib'} } }

    context 'anonymous user' do
      it 'redirects to login page' do
          get(:request_options, params)
          expect(response).to redirect_to new_user_session_url
      end
    end

    context 'logged in user' do
      before(:each) do
        sign_in @user, scope: :user
      end

      it 'does not redirect to the login page' do
        get(:request_options, params)
        expect(response).not_to redirect_to new_user_session_url
      end

    end
  end

  describe "POST #send_hold_request action" do
    context 'anonymous user' do
      it 'redirects to login page' do
          post(:send_hold_request)
          expect(response).to redirect_to new_user_session_url
      end
    end

    context 'logged in user' do
      before(:each) do
        sign_in @user, scope: :user
      end

      it 'does not redirect to the login page' do
        post(:send_hold_request, params: {last_interest_date: "", mms_id: ""  })
        expect(response).not_to redirect_to new_user_session_url
      end
    end
  end

  describe "POST #send_digitization_request action" do
    context 'anonymous user' do
      it 'redirects to login page' do
          post(:send_digitization_request)
          expect(response).to redirect_to new_user_session_url
      end
    end

    context 'logged in user' do
      before(:each) do
        sign_in @user, scope: :user
      end

      it 'does not redirect to the login page' do
        post(:send_digitization_request, params: {last_interest_date: "", mms_id: ""  })
        expect(response).not_to redirect_to new_user_session_url
      end
    end
  end

  describe "POST #send_booking_request action" do
    context 'anonymous user' do
      it 'redirects to login page' do
          post(:send_booking_request)
          expect(response).to redirect_to new_user_session_url
      end
    end

    context 'logged in user' do
      before(:each) do
        sign_in @user, scope: :user
      end

      it 'does not redirect to the login page' do
        post(:send_booking_request, params: {mms_id: "", booking_start_date: 2.days.ago, booking_end_date: 0.days.ago })
        expect(response).not_to redirect_to new_user_session_url
      end
    end
  end


end
