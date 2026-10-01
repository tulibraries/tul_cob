# frozen_string_literal: true

require "rails_helper"

RSpec.describe "parameter boundaries", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { FactoryBot.create(:user) }

  describe "bookmark creation" do
    it "persists only the permitted nested bookmark fields" do
      sign_in user

      expect {
        post bookmarks_path,
          params: {
            bookmarks: [
              {
                document_id: "book-1",
                document_type: "SolrDocument",
                unexpected: "ignored"
              }
            ],
            unexpected: "ignored"
          },
          headers: { "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest" }
      }.to change { user.bookmarks.count }.by(1)

      expect(response).to have_http_status(:ok)
      bookmark = user.bookmarks.find_by(document_id: "book-1")
      expect(bookmark.document_type.to_s).to eq("SolrDocument")
    end
  end

  describe "loan renewal" do
    it "passes only the permitted loan id array to the renewal workflow" do
      sign_in user
      renewed_ids = nil
      allow_any_instance_of(User).to receive(:renew_selected) do |_user, loan_ids|
        renewed_ids = loan_ids
        []
      end

      post "/users/renew_selected",
        params: {
          loan_ids: %w[loan-1 loan-2],
          unexpected: "ignored"
        },
        as: :json

      expect(response).to have_http_status(:ok)
      expect(renewed_ids).to eq(%w[loan-1 loan-2])
    end
  end

  describe "Alma hold requests" do
    it "permits the material type value but drops unexpected nested data" do
      sign_in user
      submitted_options = nil
      response_double = instance_double("Alma::BibRequestResponse", loggable: {})
      confirmation = instance_double(RequestConfirmation, message: "success")

      allow(Alma::BibRequest).to receive(:submit) do |options|
        submitted_options = options
        response_double
      end
      allow(RequestConfirmation).to receive(:new).and_return(confirmation)

      post hold_request_path,
        params: {
          mms_id: "",
          material_type: { value: "BOOK", unexpected: "ignored" },
          unexpected: "ignored"
        },
        headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)
      expect(submitted_options[:material_type]).to eq(value: "BOOK")
      expect(submitted_options).not_to have_key(:unexpected)
    end
  end

  describe "LibGuides search" do
    it "passes the permitted query and ignores unrelated request data" do
      allow(LibGuidesApi).to receive(:fetch).and_return([])

      get lib_guides_path, params: { q: "catalog", unexpected: "ignored" }

      expect(response).to have_http_status(:ok)
      expect(LibGuidesApi).to have_received(:fetch).with("catalog")
    end
  end
end
