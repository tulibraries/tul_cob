# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Alma web service requests", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { FactoryBot.create(:user) }
  let(:document) { SolrDocument.new("id" => "doc-1", "items_json_display" => []) }
  let(:search_service) { double("search service", fetch: document) }
  let(:request_data) do
    double(
      "request data",
      pickup_location_codes: [],
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
    allow(RequestConfirmation).to receive(:new).and_return(confirmation)
  end

  describe "GET /almaws/item/:mms_id" do
    it "renders availability for a successful Alma response" do
      get item_path("bib-1"), headers: { "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("request-url-data-bib-1")
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
      get direct_request_options_path("bib-1"), headers: { "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest" }

      expect(response).to redirect_to(new_user_session_path)
    end

    it "renders request options for an authenticated user" do
      sign_in user

      get direct_request_options_path("bib-1"), headers: { "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("request-accordian-bib-1")
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
    it "rejects an item request with no available item data" do
      sign_in user

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
