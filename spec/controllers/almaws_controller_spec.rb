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
    let(:search_service) { instance_double(Blacklight::SearchService) }
    let(:document) { SolrDocument.new(
      id: "12345",
      items_json_display: [
        {
          item_pid: "23237957740003811"
        }
      ]) }

    it "mutates the solr document with availability status" do
      # ideally once: see Alma::BibItemSet::all
      expect(HTTParty).to receive(:get).at_most(:twice).and_call_original
      expect(search_service).to receive(:fetch).and_return([:foo, document])
      allow(controller).to receive(:search_service).and_return(search_service)
      get(:item, { params: { mms_id: "merge_document_and_api", doc_id: 456 } })
      expect(document["items_json_display"][0]["availability"]).to eq "<span class=\"check\"></span>Available"
    end

    it "does nothing if the pids don't match" do
      document["items_json_display"][0]["item_pid"] = "8675309"
      expect(search_service).to receive(:fetch).and_return([:foo, document])
      allow(controller).to receive(:search_service).and_return(search_service)
      get(:item, { params: { mms_id: "merge_document_and_api", doc_id: 456 } })
      expect(document["items_json_display"][0]["availability"]).to be_nil
    end

    it "determines the availability based on the mutated document" do
      expect(search_service).to receive(:fetch).and_return([:foo, document])
      allow(controller).to receive(:search_service).and_return(search_service)
      get(:item, { params: { mms_id: "merge_document_and_api", doc_id: 456 } })
      availability = controller.instance_variable_get(:@document_availability)
      expect(availability.values.flatten.first["availability"]).to eq("<span class=\"check\"></span>Available")
    end

    it "does not include missing or lost items" do
      document["items_json_display"][0]["process_type"] = "MISSING"
      expect(search_service).to receive(:fetch).and_return([:foo, document])
      allow(controller).to receive(:search_service).and_return(search_service)
      get(:item, { params: { mms_id: "merge_document_and_api", doc_id: 456 } })
      availability = controller.instance_variable_get(:@document_availability)
      expect(availability).to be_empty
    end

    it "determines AMBLER and MAIN reserves item NOT AVAILABLE" do
      document["items_json_display"][0]["item_pid"] = "23495709760003811"
      expect(search_service).to receive(:fetch).and_return([:foo, document])
      allow(controller).to receive(:search_service).and_return(search_service)
      get(:item, { params: { mms_id: "temp_location_reserves", doc_id: 456 } })
      availability = controller.instance_variable_get(:@document_availability)
      expect(availability.values.flatten.first["availability"]).to eq("<span class=\"close-icon\"></span>Not Available")
    end

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
      pickup_location: "someplace" ,
      request_level: "bib",

       } } }

    before(:each) do
      allow(controller).to receive(:current_user) { @user }
      allow(controller).to receive(:params) { params }
      controller.request_options
    end

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

    context "params :pickup_locations && :request_level not set" do
      let(:params) { {} }

      it "sets @make_modal_link to true since we are not coming via modal" do
        make_modal_link = controller.instance_variable_get("@make_modal_link")
        expect(make_modal_link).to eq(true)
      end
    end

    context "params :pickup_locations && :request_level are set" do
      let(:params) { { pickup_location: "someplace" , request_level: "bib" } }

      it "sets @make_modal_link to false since we are coming via modal" do
        make_modal_link = controller.instance_variable_get("@make_modal_link")
        expect(make_modal_link).to eq(false)
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

      it "doesn't raise an exception for correctly formatted date for last_interest_date" do
        post(:send_hold_request, params: { last_interest_date: "2018-08-15", mms_id: ""  })
        expect { response }.not_to raise_error
      end

      it "doesn't raise an exception for correctly formatted material type" do
        post(:send_hold_request, params: { material_type: { value: "BOOK", mms_id: ""  } })
        expect { response }.not_to raise_error
      end
    end
  end

  describe "POST #send_asrs_request action" do
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

      it "doesn't raise an exception for correctly formatted date for last_interest_date" do
        post(:send_hold_request, params: { last_interest_date: "2018-08-15", mms_id: ""  })
        expect { response }.not_to raise_error
      end

      it "doesn't raise an exception for correctly formatted material type" do
        post(:send_hold_request, params: { material_type: { value: "BOOK", mms_id: ""  } })
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

      it "doesn't raise an exception for correctly formatted date for last_interest_date" do
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

      it "doesn't raise an exception for correctly formatted date for booking dates" do
        post(:send_booking_request, params: { booking_start_date: "2018-08-16", booking_end_date: "2018-08-20", mms_id: ""  })
        expect { response }.not_to raise_error
      end
    end
  end

  describe "#date_or_nil" do

    it "returns a formatted date when passed a YYYY-MM-DD string" do
      expect(controller.send(:date_or_nil, "2018-10-18")).to be_a_kind_of Date
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

  describe "handling Alma::BibItemSet::ResponseError exceptions" do
    let(:params) { { params: { mms_id: "991026719119703811" } } }

    it "renders the html response" do
      allow(controller).to receive(:item) { raise Alma::BibItemSet::ResponseError.new("test") }
      get :item, params
      expect(response.body).to eq("<p class='m-2'>Please contact the library service desk for additional assistance.</p>")
    end
  end

  describe "assigning request levels correctly for ASRS and nonASRS items" do
    let(:items)  { [item1, item2 ] }

    context "default behavior empty list" do
      let(:items) { [] }
      it "should be bib" do
        expect(controller.send(:get_request_level, items)).to eq("bib")
      end
    end

    context "asrs items only without descriptions" do
      let(:item1) {
        Alma::BibItem.new("item_data" => { "library" => { "value" => "ASRS", "description" => "Library" } })
      }

      let(:item2) {
        Alma::BibItem.new("item_data" => { "library" => { "value" => "ASRS", "description" => "Library" } })
      }

      it "should be a bib level request" do
        expect(controller.send(:get_request_level, items)).to eq("bib")
        expect(controller.send(:get_request_level, items, "asrs")).to eq("bib")
      end
    end

    context "mixed asrs and non asrs items without descriptions" do
      let(:item1) {
        Alma::BibItem.new("item_data" => { "library" => { "value" => "MAIN", "description" => "Library" } })
      }

      let(:item2) {
        Alma::BibItem.new("item_data" => { "library" => { "value" => "ASRS", "description" => "Library" } })
      }

      it "should return bib for non asrs hold requests" do
        expect(controller.send(:get_request_level, items)).to eq("bib")
      end

      it "should return item for asrs hold requests" do
        expect(controller.send(:get_request_level, items, "asrs")).to eq("item")
      end
    end

    context "mixed asrs with descriptions" do
      let(:item1) {
        Alma::BibItem.new("item_data" => { "library" => { "value" => "MAIN", "description" => "Library" }, "description" => "v1" })
      }

      let(:item2) {
        Alma::BibItem.new("item_data" => { "library" => { "value" => "ASRS", "description" => "Library" } })
      }

      it "should return item for non asrs hold requests" do
        expect(controller.send(:get_request_level, items)).to eq("item")
      end

      it "should return item for asrs hold requests" do
        expect(controller.send(:get_request_level, items, "asrs")).to eq("item")
      end
    end
  end
end
