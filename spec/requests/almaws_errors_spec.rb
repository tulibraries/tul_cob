# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Almaws request errors", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { FactoryBot.create(:user) }
  let(:mms_id) { "991030207479703811" }
  let(:record_url) { solr_document_url(mms_id) }
  let(:hold_params) { { mms_id: mms_id, hold_pickup_location: "MAIN", material_type: "BOOK", request_level: "bib" } }

  before { sign_in user }

  describe "POST /almaws/request/hold with an invalid authenticity token" do
    around do |example|
      original_forgery_setting = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = original_forgery_setting
    end

    it "redirects back to the record with a retry message" do
      post hold_request_path, params: hold_params, headers: { "HTTP_REFERER" => record_url }

      expect(response).to redirect_to(record_url)
      expect(flash[:notice]).to eq("Your request could not be submitted. Please try again.")
    end
  end

  describe "POST /almaws/request/hold when an unexpected error occurs" do
    before do
      allow(Honeybadger).to receive(:notify)
      allow_any_instance_of(AlmawsController).to receive(:send_hold_request).and_raise(StandardError, "unexpected failure")
    end

    it "renders the internal server error page" do
      post hold_request_path, params: hold_params

      expect(response).to have_http_status(:internal_server_error)
      expect(response.body).to include("We're sorry, but something went wrong.")
    end
  end
end
