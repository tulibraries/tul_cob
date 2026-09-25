# frozen_string_literal: true

require "rails_helper"

RSpec.describe AlmawsController, type: :controller do
  let(:search_service) { instance_double(Blacklight::SearchService) }

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
    let(:document) { SolrDocument.new(
      id: "12345",
      items_json_display: [
        {
          item_pid: "23237957740003811",
          permanent_library: "AMBLER",
          permanent_location: "media",
          current_library: "AMBLER",
          current_location: "media",
        }
      ]) }

    it "mutates the solr document with availability status" do
      expect(HTTParty).to receive(:get).at_most(:twice).and_call_original
      expect(search_service).to receive(:fetch).and_return(document)
      allow(controller).to receive(:search_service).and_return(search_service)

      get(:item, **{ params: { mms_id: "merge_document_and_api", doc_id: 456 } })

      expect(document["items_json_display"][0]["availability"]).to eq "Available"
    end

    it "does nothing if the pids don't match" do
      document["items_json_display"][0]["item_pid"] = "8675309"
      expect(search_service).to receive(:fetch).and_return(document)
      allow(controller).to receive(:search_service).and_return(search_service)
      get(:item, **{ params: { mms_id: "merge_document_and_api", doc_id: 456 } })
      expect(document["items_json_display"][0]["availability"]).to be_nil
    end

    it "determines the availability based on the mutated document" do
      expect(search_service).to receive(:fetch).and_return(document)
      allow(controller).to receive(:search_service).and_return(search_service)
      get(:item, **{ params: { mms_id: "merge_document_and_api", doc_id: 456 } })
      availability = controller.instance_variable_get(:@document_availability)
      expect(availability.dig("Ambler Campus Library", "Media").flatten.first["availability"]).to eq("Available")
    end

    it "does not include missing or lost items" do
      document["items_json_display"][0]["process_type"] = "MISSING"
      expect(search_service).to receive(:fetch).and_return(document)
      allow(controller).to receive(:search_service).and_return(search_service)
      get(:item, **{ params: { mms_id: "merge_document_and_api", doc_id: 456 } })
      availability = controller.instance_variable_get(:@document_availability)
      expect(availability).to be_empty
    end

    it "filters technical migration items" do
      item_set = double
      technical_item = Alma::BibItem.new("item_data" => { "process_type" => { "value" => "TECHNICAL" } })
      available_item = Alma::BibItem.new("item_data" => { "process_type" => { "value" => "" } })

      expect(Alma::BibItem).to receive(:find)
        .with("technical_migration", limit: 100, offset: 0, expand: "due_date")
        .and_return(item_set)
      expect(item_set).to receive(:all).and_return([technical_item, available_item])

      expect(controller.send(:get_bib_items, "technical_migration")).to eq([available_item])
    end

    context "anonymous user" do
      it "does not redirect to login page" do
        get(:item, **params)
        expect(response).not_to redirect_to new_user_session_url
      end
    end

    context "logged in user" do
      before(:each) do
        sign_in @user, scope: :user
      end

      it "doesn't render the layout, even when there's an error", with_rescue: true do
        allow(Alma::BibItem).to receive(:find).and_raise("oof")
        get :item, **params
        expect(response).not_to render_template("layouts/blacklight")
      end
    end
  end

  describe "GET #request_options action" do

    let(:params) { { params: {
      mms_id: 123,
      pickup_location: "someplace" ,
      request_level: "bib"
                     } } }
    let(:document) { SolrDocument.new(
      id: "12345",
      items_json_display: [
        {
          item_pid: "23237957740003811"
        }
      ]) }


    before(:each) do
      allow(controller).to receive(:current_user) { @user }
    end

    context "anonymous user" do
      it "redirects to login page" do
        get(:request_options, **params)
        expect(response).to redirect_to new_user_session_url
      end
    end

    context "logged in user" do
      before(:each) do
        sign_in @user, scope: :user
      end

      it "does not redirect to the login page" do
        get(:request_options, **params)
        expect(response).not_to redirect_to new_user_session_url
      end

    end

    context "params :pickup_locations && :request_level not set" do
      let(:params) { { params: { mms_id: 123 } } }

      it "sets @make_modal_link to true since we are not coming via modal" do
        sign_in @user, scope: :user
        get(:request_options, **params)
        make_modal_link = controller.instance_variable_get("@make_modal_link")
        expect(make_modal_link).to eq(true)
      end
    end

    context "params :pickup_locations && :request_level are set" do
      let(:params) { { params: { mms_id: 123, pickup_location: "someplace" , request_level: "bib" } } }

      it "sets @make_modal_link to false since we are coming via modal" do
        sign_in @user, scope: :user
        get(:request_options, **params)
        make_modal_link = controller.instance_variable_get("@make_modal_link")
        expect(make_modal_link).to eq(false)
      end
    end

    context "bad response received from alma (Alma::RequestOptions::ResponseError)" do
      render_views

      let(:bib_item) { class_double(Alma::BibItem) }
      let(:bib_item_set) { instance_double(Alma::BibItemSet) }
      let(:request_data) do
        instance_double(RequestData,
          material_types: [],
          equipment_locations: [],
          booking_locations: [],
          pickup_locations: [],
          item_level_locations: [],
          request_level: "bib",
          item_holding_ids: [],
          item_holding_ids_backup: [],
          material_types_and_descriptions: [])
      end

      before(:each) do
        allow(controller).to receive(:search_service).and_return(search_service)
        expect(search_service).to receive(:fetch).and_return(document)
        allow(bib_item).to receive(:find).and_return(bib_item_set)
        allow(bib_item_set).to receive(:filter_missing_and_lost).and_return(bib_item_set)
        allow(RequestData).to receive(:new).and_return(request_data)
        allow(Alma::RequestOptions).to receive(:get).and_raise(Alma::RequestOptions::ResponseError, "phhhht")
        sign_in @user, scope: :user
        get(:request_options, **params)
      end

      it "sends a 502 error with a layout-less error message in the body", with_rescue: true do
        expect(response).to have_http_status 502
        expect(response.body).to include "There was an error with our request service."
        expect(response).not_to render_template("layouts/blacklight")
      end

      it "forwards the alma error to honeybadger", with_rescue: true do
        error = "Alma::RequestOptions::ResponseError: {\"error\":\"phhhht\"}"

        Honeybadger.flush
        notice = Honeybadger::Backend::Test.notifications[:notices].last
        expect(notice.error_message.encode("UTF-8")).to eq(error)
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
        post(:send_hold_request, params: { mms_id: ""  })
        expect(response).not_to redirect_to new_user_session_url
      end

      it "doesn't raise an exception for empty pickup_location" do
        post(:send_hold_request, params: { pickup_location: nil, mms_id: ""  })
        expect { response }.not_to raise_error
      end

      it "doesn't raise an exception for correctly formatted material type" do
        post(:send_hold_request, params: { material_type: { value: "BOOK", mms_id: ""  } })
        expect { response }.not_to raise_error
      end

      it "submits an item request for ASRS when ASRS and Charles stacks copies are both available" do
        allow(controller).to receive(:get_bib_items).and_return([
          Alma::BibItem.new(
            "holding_data" => { "holding_id" => "holding_main" },
            "item_data" => {
              "pid" => "item_main",
              "description" => "",
              "library" => { "value" => "MAIN", "desc" => "Charles Library" },
              "base_status" => { "value" => "1", "desc" => "Item in place" }
            }
          ),
          Alma::BibItem.new(
            "holding_data" => { "holding_id" => "holding_asrs" },
            "item_data" => {
              "pid" => "item_asrs",
              "description" => "",
              "library" => { "value" => "ASRS", "desc" => "Charles BookBot" },
              "base_status" => { "value" => "1", "desc" => "Item in place" }
            }
          )
        ])

        response_double = double("request_response", request_id: "1", managed_by_library_code: "ASRS", loggable: {})
        allow(Alma::ItemRequest).to receive(:submit).and_return(response_double)
        allow(Alma::BibRequest).to receive(:submit)

        post(:send_hold_request, params: {
          mms_id: "foo",
          hold_pickup_location: "MAIN",
          material_type: "BOOK",
          request_level: "bib"
        })

        expect(Alma::ItemRequest).to have_received(:submit).with(
          hash_including(
            holding_id: "holding_asrs",
            item_pid: "item_asrs",
            pickup_location_library: "MAIN"
          )
        )
        expect(Alma::BibRequest).not_to have_received(:submit)
      end

      it "falls back to a bib request when no same-campus copy is available" do
        allow(controller).to receive(:get_bib_items).and_return([
          Alma::BibItem.new(
            "holding_data" => { "holding_id" => "holding_ambler" },
            "item_data" => {
              "pid" => "item_ambler",
              "description" => "",
              "library" => { "value" => "AMBLER", "desc" => "Ambler Campus Library" },
              "base_status" => { "value" => "1", "desc" => "Item in place" }
            }
          ),
          Alma::BibItem.new(
            "holding_data" => { "holding_id" => "holding_hsl" },
            "item_data" => {
              "pid" => "item_hsl",
              "description" => "",
              "library" => { "value" => "GINSBURG", "desc" => "Ginsburg Health Science Library" },
              "base_status" => { "value" => "1", "desc" => "Item in place" }
            }
          )
        ])

        response_double = double("request_response", request_id: "1", managed_by_library_code: "AMBLER", loggable: {})
        allow(Alma::ItemRequest).to receive(:submit)
        allow(Alma::BibRequest).to receive(:submit).and_return(response_double)

        post(:send_hold_request, params: {
          mms_id: "foo",
          hold_pickup_location: "MAIN",
          material_type: "BOOK",
          request_level: "bib"
        })

        expect(Alma::ItemRequest).not_to have_received(:submit)
        expect(Alma::BibRequest).to have_received(:submit)
      end

      it "normalizes the any available copy sentinel back to a blank description" do
        allow(controller).to receive(:get_bib_items).and_return([
          Alma::BibItem.new(
            "holding_data" => { "holding_id" => "holding_main" },
            "item_data" => {
              "pid" => "item_main",
              "description" => "",
              "library" => { "value" => "MAIN", "desc" => "Charles Library" },
              "base_status" => { "value" => "1", "desc" => "Item in place" }
            }
          )
        ])

        response_double = double("request_response", request_id: "1", managed_by_library_code: "MAIN", loggable: {})
        allow(Alma::BibRequest).to receive(:submit).and_return(response_double)

        post(:send_hold_request, params: {
          mms_id: "foo",
          hold_description: RequestData::BLANK_DESCRIPTION_VALUE,
          hold_pickup_location: "MAIN",
          material_type: "BOOK",
          request_level: "bib"
        })

        expect(Alma::BibRequest).to have_received(:submit).with(hash_including(description: ""))
      end

      it "shows an error and notifies Honeybadger when a hold request fails" do
        allow(controller).to receive(:same_pickup_item_request_options).and_return(nil)
        allow(Alma::BibRequest).to receive(:submit).and_raise(StandardError, "request failed")
        allow(Honeybadger).to receive(:notify)

        post :send_hold_request, params: {
          mms_id: "bib-1",
          hold_pickup_location: "MAIN",
          material_type: "BOOK"
        }

        expect(Honeybadger).to have_received(:notify).with(a_string_including("request failed"))
        expect(flash[:notice]).to include("There was an error processing your request")
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
        post(:send_hold_request, params: { mms_id: ""  })
        expect(response).not_to redirect_to new_user_session_url
      end

      it "doesn't raise an exception for empty pickup_location" do
        post(:send_hold_request, params: { pickup_location: nil, mms_id: ""  })
        expect { response }.not_to raise_error
      end

      it "doesn't raise an exception for correctly formatted material type" do
        post(:send_hold_request, params: { material_type: { value: "BOOK", mms_id: ""  } })
        expect { response }.not_to raise_error
      end

      it "submits a bib request when the request level is bib" do
        response_double = double("request_response", request_id: "1", managed_by_library_code: "MAIN", loggable: {})
        confirmation = instance_double(RequestConfirmation, message: "success")
        allow(Alma::BibRequest).to receive(:submit).and_return(response_double)
        allow(RequestConfirmation).to receive(:new).and_return(confirmation)

        post :send_asrs_request, params: {
          mms_id: "bib-1",
          asrs_request_level: "bib",
          asrs_description: "Book",
          asrs_pickup_location: "MAIN",
          material_type: "BOOK",
          asrs_comment: "Comment"
        }

        expect(Alma::BibRequest).to have_received(:submit).with(
          hash_including(
            mms_id: "bib-1",
            request_type: "HOLD",
            pickup_location_library: "MAIN",
            description: "Book"
          )
        )
        expect(flash[:notice]).to eq("success")
      end

      it "submits an item request for the first matching ASRS item" do
        response_double = double("request_response", request_id: "1", managed_by_library_code: "ASRS", loggable: {})
        confirmation = instance_double(RequestConfirmation, message: "success")
        allow(Alma::ItemRequest).to receive(:submit).and_return(response_double)
        allow(RequestConfirmation).to receive(:new).and_return(confirmation)

        post :send_asrs_request, params: {
          mms_id: "bib-1",
          asrs_request_level: "item",
          asrs_description: "Book",
          asrs_pickup_location: "MAIN",
          material_type: "BOOK",
          available_asrs_items: [
            { description: "Different book", holding_id: "holding-1", item_pid: "item-1" },
            { description: "Book", holding_id: "holding-2", item_pid: "item-2" },
            { description: "Book", holding_id: "holding-3", item_pid: "item-3" }
          ]
        }

        expect(Alma::ItemRequest).to have_received(:submit).with(
          hash_including(holding_id: "holding-2", item_pid: "item-2")
        )
        expect(Alma::ItemRequest).to have_received(:submit).once
        expect(flash[:notice]).to eq("success")
      end

      it "shows an error when no ASRS item matches the description" do
        allow(Alma::ItemRequest).to receive(:submit)
        allow(Alma::BibRequest).to receive(:submit)

        post :send_asrs_request, params: {
          mms_id: "bib-1",
          asrs_request_level: "item",
          asrs_description: "Book",
          asrs_pickup_location: "MAIN",
          material_type: "BOOK",
          available_asrs_items: [
            { description: "Different book", holding_id: "holding-1", item_pid: "item-1" }
          ]
        }

        expect(Alma::ItemRequest).not_to have_received(:submit)
        expect(Alma::BibRequest).not_to have_received(:submit)
        expect(flash[:notice]).to include("There was an error processing your request")
      end

      it "notifies Honeybadger and shows an error when the ASRS request fails" do
        allow(Alma::BibRequest).to receive(:submit).and_raise(StandardError, "request failed")
        allow(Honeybadger).to receive(:notify)

        post :send_asrs_request, params: {
          mms_id: "bib-1",
          asrs_request_level: "bib",
          asrs_description: "Book",
          asrs_pickup_location: "MAIN",
          material_type: "BOOK"
        }

        expect(Honeybadger).to have_received(:notify).with(a_string_including("request failed"))
        expect(flash[:notice]).to include("There was an error processing your request")
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
        post(:send_digitization_request, params: { mms_id: ""  })
        expect(response).not_to redirect_to new_user_session_url
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

      it "shows an error when digitization submission fails" do
        allow(Alma::BibRequest).to receive(:submit).and_raise(StandardError, "request failed")

        post :send_digitization_request, params: { mms_id: "bib-1" }

        expect(flash[:notice]).to include("There was an error processing your request")
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

      it "confirms a successful booking request" do
        response_double = double("request_response", request_id: "1", managed_by_library_code: "MAIN", loggable: {})
        confirmation = instance_double(RequestConfirmation, message: "success")
        allow(Alma::BibRequest).to receive(:submit).and_return(response_double)
        allow(RequestConfirmation).to receive(:new).and_return(confirmation)

        post :send_booking_request, params: {
          mms_id: "bib-1",
          booking_start_date: "2018-08-16",
          booking_end_date: "2018-08-20",
          booking_description: "Book",
          booking_pickup_location: "MAIN",
          material_type: "BOOK"
        }

        expect(Alma::BibRequest).to have_received(:submit).with(
          hash_including(
            mms_id: "bib-1",
            request_type: "BOOKING",
            booking_start_date: Date.new(2018, 8, 16),
            booking_end_date: Date.new(2018, 8, 20)
          )
        )
        expect(flash[:notice]).to eq("success")
      end

      it "reports when the item is already booked" do
        allow(Alma::BibRequest).to receive(:submit).and_raise(
          Alma::BibRequest::ItemAlreadyExists.new("already booked")
        )

        post :send_booking_request, params: { mms_id: "bib-1" }

        expect(flash[:notice]).to eq("This item is already booked for those dates.")
      end

      it "reports when booking submission fails" do
        allow(Alma::BibRequest).to receive(:submit).and_raise(StandardError, "request failed")

        post :send_booking_request, params: { mms_id: "bib-1" }

        expect(flash[:notice]).to include("There was an error processing your request")
      end
    end
  end

  describe "request option branches" do
    let(:request_data) do
      instance_double(
        RequestData,
        material_types_and_descriptions: [],
        material_types: [],
        pickup_locations: [],
        item_level_locations: [],
        equipment_locations: [],
        booking_locations: [],
        request_level: "item",
        item_holding_ids: { "holding-1" => "item-1" },
        item_holding_ids_backup: { "holding-2" => "item-1" }
      )
    end
    let(:document) do
      SolrDocument.new("format" => ["Book"], "creator_display" => ["Author"])
    end

    before do
      sign_in @user, scope: :user
      allow(controller).to receive(:search_service).and_return(search_service)
      allow(search_service).to receive(:fetch).and_return(document)
      allow(controller).to receive(:get_bib_items).and_return([])
      allow(RequestData).to receive(:new).and_return(request_data)
    end

    it "loads bib request options and document metadata" do
      request_options = double("request_options", request_options: ["option"], loggable: {})
      allow(request_data).to receive(:request_level).and_return("bib")
      allow(Alma::RequestOptions).to receive(:get).and_return(request_options)

      get :request_options, params: { mms_id: "bib-1" }

      expect(Alma::RequestOptions).to have_received(:get).with("bib-1", user_id: @user.uid)
      expect(controller.instance_variable_get(:@books)).to eq(["Book"])
      expect(controller.instance_variable_get(:@author)).to eq("Author")
      expect(controller.instance_variable_get(:@request_options)).to eq(request_options)
    end

    it "retries item request options with backup holding ids when the first result is empty" do
      empty_options = double("empty_options", request_options: nil, loggable: {})
      backup_options = double("backup_options", request_options: ["option"], loggable: {})
      allow(Alma::ItemRequestOptions).to receive(:get).and_return(empty_options, backup_options)

      get :request_options, params: { mms_id: "bib-1" }

      expect(Alma::ItemRequestOptions).to have_received(:get).with(
        "bib-1", "holding-1", "item-1", user_id: @user.uid
      )
      expect(Alma::ItemRequestOptions).to have_received(:get).with(
        "bib-1", "holding-2", "item-1", user_id: @user.uid
      )
      expect(controller.instance_variable_get(:@request_options)).to eq(backup_options)
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

    it "renders the html response", with_rescue: true do
      allow(controller).to receive(:item) { raise Alma::BibItemSet::ResponseError.new("test") }
      get :item, **params
      expect(response.body).to eq("<p class='m-2'>Availability information can not be loaded. Contact a librarian for help.</p>")
      expect(response.code).to eq "502"
    end
  end
end
