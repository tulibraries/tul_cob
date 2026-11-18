# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Alma web service requests", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { FactoryBot.create(:user) }
  let(:document) { SolrDocument.new("id" => "doc-1", "items_json_display" => []) }
  let(:populated_document) do
    SolrDocument.new(
      "id" => "doc-1",
      "format" => ["Book"],
      "title_statement_display" => "King Solomon's mines",
      "items_json_display" => [
        {
          "item_pid" => "23237957740003811",
          "permanent_library" => "AMBLER",
          "permanent_location" => "media",
          "current_library" => "AMBLER",
          "current_location" => "media",
          "call_number" => "DVD 13 A165",
          "material_type" => "DVD"
        }
      ]
    )
  end
  let(:search_service) { double("search service", fetch: document) }
  let(:request_data) do
    double(
      "request data",
      pickup_location_codes: ["MAIN"],
      get_request_level: "bib",
      material_types_and_descriptions: [],
      material_types: [],
      pickup_locations: [],
      item_level_locations: [],
      equipment_locations: [],
      booking_locations: [],
      request_level: "bib",
      item_holding_ids: [],
      item_holding_ids_backup: [],
      same_pickup_item_request: nil
    )
  end
  let(:request_options) do
    double(
      "request options",
      hold_allowed?: false,
      digitization_allowed?: false,
      booking_allowed?: false,
      resource_sharing_broker_allowed?: false,
      request_options: []
    )
  end
  let(:alma_response) do
    double(
      "Alma request response",
      request_id: "request-1",
      managed_by_library_code: "MAIN",
      loggable: {}
    )
  end
  let(:confirmation) { double("request confirmation", message: "Request submitted") }

  before do
    allow_any_instance_of(AlmawsController).to receive(:search_service).and_return(search_service)
    allow_any_instance_of(AlmawsController).to receive(:get_bib_items).and_return([])
    allow_any_instance_of(AlmawsController).to receive(:same_pickup_item_request_options).and_return(nil)
    allow_any_instance_of(AlmawsController).to receive(:get_bib_request_options).and_return(request_options)
    allow(RequestData).to receive(:new).and_return(request_data)
    allow(Alma::BibRequest).to receive(:submit).and_return(alma_response)
    allow(Alma::ItemRequest).to receive(:submit).and_return(alma_response)
    allow(RequestConfirmation).to receive(:new).and_return(confirmation)
  end

  describe "GET /almaws/item/:mms_id" do
    it "renders availability from a populated Alma response" do
      allow(search_service).to receive(:fetch).and_return(populated_document)
      allow_any_instance_of(AlmawsController).to receive(:get_bib_items).and_call_original
      allow(RequestData).to receive(:new).and_call_original

      get item_path("merge_document_and_api"), headers: { "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Available")
      expect(response.body).to include("Ambler Campus Library")
      expect(response.body).to include("DVD 13 A165")
    end

    it "renders an empty availability response when the Solr record is missing" do
      allow(search_service).to receive(:fetch).and_raise(Blacklight::Exceptions::RecordNotFound)

      get item_path("bib-1"), headers: { "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("availability")
    end
  end

  describe "GET /almaws/request/:mms_id" do
    it "requires authentication" do
      get direct_request_options_path("bib-1")

      expect(response).to redirect_to(new_user_session_path)
    end

    it "renders an allowed hold form from a populated Alma response" do
      sign_in user
      allow(search_service).to receive(:fetch).and_return(populated_document)
      allow_any_instance_of(AlmawsController).to receive(:get_bib_items).and_call_original
      allow_any_instance_of(AlmawsController).to receive(:get_bib_request_options).and_call_original
      allow(RequestData).to receive(:new).and_call_original
      stub_request(:any, %r{almaws/v1/bibs/merge_document_and_api/request-options})
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: JSON.dump(
            request_option: [
              {
                type: { value: "HOLD", desc: "Hold" },
                request_url: "https://api-na.hosted.exlibrisgroup.com/almaws/v1/requests/"
              }
            ]
          )
        )

      get request_options_path("merge_document_and_api", "MAIN", "bib"), headers: { "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="hold-request-form"')
      expect(response.body).to include('name="hold_pickup_location"')
      expect(response.body).to include("Charles Library")
      expect(response.body).to include('name="material_type"')
    end
  end

  describe "POST /almaws/request/hold" do
    it "requires authentication" do
      post hold_request_path, headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "submits a hold request and redirects with the confirmation" do
      sign_in user

      post hold_request_path,
        params: { mms_id: "bib-1", hold_pickup_location: "MAIN", material_type: "BOOK" },
        headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq("Request submitted")
      expect(Alma::BibRequest).to have_received(:submit).with(
        hash_including(mms_id: "bib-1", pickup_location_library: "MAIN")
      )
    end

    it "turns an upstream timeout into the request error response" do
      sign_in user
      allow(Alma::BibRequest).to receive(:submit).and_raise(Timeout::Error)

      post hold_request_path,
        params: { mms_id: "bib-1", hold_pickup_location: "MAIN", material_type: "BOOK" },
        headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to include("There was an error processing your request")
    end
  end

  describe "POST /almaws/request/asrs" do
    it "rejects an item request when available item data is omitted" do
      sign_in user
      allow(Honeybadger).to receive(:notify)

      post asrs_request_path,
        params: {
          mms_id: "bib-1",
          asrs_request_level: "item",
          asrs_description: "Book",
          asrs_pickup_location: "MAIN",
          material_type: "BOOK"
        },
        headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to include("There was an error processing your request")
      expect(Alma::BibRequest).not_to have_received(:submit)
      expect(Alma::ItemRequest).not_to have_received(:submit)
      expect(Honeybadger).to have_received(:notify).with(a_string_including("select"))
    end

    it "rejects an item request when available item data is explicitly empty" do
      sign_in user
      allow(Honeybadger).to receive(:notify)

      post asrs_request_path,
        params: {
          mms_id: "bib-1",
          asrs_request_level: "item",
          asrs_description: "Book",
          asrs_pickup_location: "MAIN",
          material_type: "BOOK",
          available_asrs_items: []
        },
        headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to include("There was an error processing your request")
      expect(Alma::BibRequest).not_to have_received(:submit)
      expect(Alma::ItemRequest).not_to have_received(:submit)
      expect(Honeybadger).not_to have_received(:notify)
    end
  end

  describe "POST /almaws/request/booking" do
    it "submits a booking request for valid dates" do
      sign_in user

      post booking_request_path,
        params: {
          mms_id: "bib-1",
          booking_start_date: "2026-11-20",
          booking_end_date: "2026-11-22",
          booking_pickup_location: "MAIN",
          material_type: "BOOK"
        },
        headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq("Request submitted")
      expect(Alma::BibRequest).to have_received(:submit).with(
        hash_including(
          mms_id: "bib-1",
          request_type: "BOOKING",
          booking_start_date: Date.new(2026, 11, 20),
          booking_end_date: Date.new(2026, 11, 22)
        )
      )
    end
  end

  describe "POST /almaws/request/digitization" do
    it "submits a digitization request with the requested page range" do
      sign_in user

      post digitization_request_path,
        params: {
          mms_id: "bib-1",
          from_page: "12",
          to_page: "18",
          material_type: "BOOK"
        },
        headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq("Request submitted")
      expect(Alma::BibRequest).to have_received(:submit).with(
        hash_including(
          mms_id: "bib-1",
          request_type: "DIGITIZATION",
          required_pages_range: [{ from_page: "12", to_page: "18" }]
        )
      )
    end

    it "turns a connection failure into the request error response" do
      sign_in user
      allow(Alma::BibRequest).to receive(:submit).and_raise(Errno::ECONNREFUSED)

      post digitization_request_path,
        params: { mms_id: "bib-1", material_type: "BOOK" },
        headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to include("There was an error processing your request")
    end
  end
end
