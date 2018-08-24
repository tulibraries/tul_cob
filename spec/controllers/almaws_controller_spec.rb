# frozen_string_literal: true

require "spec_helper"
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

    let(:params) { { params: { mms_id: 123 } } }

    context "anonymous user" do
      it "does not redirect to login page" do
        get(:item, params)
        expect(response).not_to redirect_to new_user_session_url
      end
    end
  end

  describe "GET #request_options action" do

    let(:params) { { params: {
      mms_id: 123,
      pickup_location: "some,place" ,
      request_level: "bib",

       } } }

    context "anonymous user" do
      it "redirects to login page" do
        get(:request_options, params)
        expect(response).to redirect_to new_user_session_url
      end
    end

    context "logged in user" do
      before(:each) do
        sign_in @user, scope: :user
      end

      it "does not redirect to the login page" do
        get(:request_options, params)
        expect(response).not_to redirect_to new_user_session_url
      end

    end
  end

  describe "POST #send_hold_request action" do
    context "anonymous user" do
      it "redirects to login page" do
        post(:send_hold_request)
        expect(response).to redirect_to new_user_session_url
      end
    end

    context "logged in user" do
      before(:each) do
        sign_in @user, scope: :user
      end

      it "does not redirect to the login page" do
        post(:send_hold_request, params: { last_interest_date: "", mms_id: ""  })
        expect(response).not_to redirect_to new_user_session_url
      end

      it "doesn't raise an exception for empty pickup_location" do
        post(:send_hold_request, params: { last_interest_date: "", pickup_location: nil, mms_id: ""  })
        expect { response }.not_to raise_error
      end

      it "doesn't raise an exception for non-empty string for last_interest_date" do
        post(:send_hold_request, params: { last_interest_date: "string", mms_id: ""  })
        expect { response }.not_to raise_error
      end

      it "doesn't raise an exception for empty string for last_interest_date" do
        post(:send_hold_request, params: { last_interest_date: "", mms_id: ""  })
        expect { response }.not_to raise_error
      end

      it "doesn't raise an exception for correctly formattted date for last_interest_date" do
        post(:send_hold_request, params: { last_interest_date: "2018-08-15", mms_id: ""  })
        expect { response }.not_to raise_error
      end
    end
  end

  describe "POST #send_digitization_request action" do
    context "anonymous user" do
      it "redirects to login page" do
        post(:send_digitization_request)
        expect(response).to redirect_to new_user_session_url
      end
    end

    context "logged in user" do
      before(:each) do
        sign_in @user, scope: :user
      end

      it "does not redirect to the login page" do
        post(:send_digitization_request, params: { last_interest_date: "", mms_id: ""  })
        expect(response).not_to redirect_to new_user_session_url
      end

      it "doesn't raise an exception for non-empty string for last_interest_date" do
        post(:send_digitization_request, params: { last_interest_date: "string", mms_id: ""  })
        expect { response }.not_to raise_error
      end

      it "doesn't raise an exception for empty string for last_interest_date" do
        post(:send_digitization_request, params: { last_interest_date: "", mms_id: ""  })
        expect { response }.not_to raise_error
      end

      it "doesn't raise an exception for correctly formattted date for last_interest_date" do
        post(:send_digitization_request, params: { last_interest_date: "2018-08-15", mms_id: ""  })
        expect { response }.not_to raise_error
      end

      it "includes page range params in Alma api request" do
        post(:send_digitization_request, params: { from_page: "123", to_page: "129", mms_id: ""  })
        expect(WebMock).to have_requested(:post, /.*request.*/).
          with(body: hash_including(
            required_pages_range: [{
              from_page: "123", to_page: "129"
              }]
            )
          )
      end
    end
  end

  describe "POST #send_booking_request action" do
    context "anonymous user" do
      it "redirects to login page" do
        post(:send_booking_request)
        expect(response).to redirect_to new_user_session_url
      end
    end

    context "logged in user" do
      before(:each) do
        sign_in @user, scope: :user
      end

      it "does not redirect to the login page" do
        post(:send_booking_request, params: { mms_id: "", booking_start_date: 2.days.ago, booking_end_date: 0.days.ago })
        expect(response).not_to redirect_to new_user_session_url
      end

      it "doesn't raise an exception for non-empty string for booking dates" do
        post(:send_booking_request, params: { booking_start_date: "string", booking_end_date: "string", mms_id: ""  })
        expect { response }.not_to raise_error
      end

      it "doesn't raise an exception for empty string for booking dates" do
        post(:send_booking_request, params: { booking_start_date: "", booking_end_date: "", mms_id: ""  })
        expect { response }.not_to raise_error
      end

      it "doesn't raise an exception for correctly formattted date for booking dates" do
        post(:send_booking_request, params: { booking_start_date: "2018-08-16", booking_end_date: "2018-08-20", mms_id: ""  })
        expect { response }.not_to raise_error
      end
    end
  end

  describe "#date_or_nil" do

    it "returns a formatted date when passed a YYYY-MM-DD string" do
      expect(controller.send(:date_or_nil, "10-18-2018")).to be_a_kind_of Date
    end

    it "returns nil when passed a string" do
      expect(controller.send(:date_or_nil, "string")).to be nil
    end

    it "returns nil when passed an empty string" do
      expect(controller.send(:date_or_nil, "")).to be nil
    end

    it "returns nil when passed nil" do
      expect(controller.send(:date_or_nil, nil)).to be nil
    end



  end
end
