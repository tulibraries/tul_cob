# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Catalog errors", type: :request do
  describe "invalid document id handling" do

    before do
      allow_any_instance_of(Blacklight::SearchService)
        .to receive(:fetch)
        .and_raise(Blacklight::Exceptions::RecordNotFound.new("not found"))
    end

    let(:bad_id) { "nonexistent123" }

    it "renders not found for RIS" do
      get solr_document_path(bad_id, format: :ris)
      expect(response).to have_http_status(:not_found)
      expect(response.body).to eq("Record not found")
    end

    it "renders not found for JSON" do
      get solr_document_path(bad_id, format: :json)
      expect(response).to have_http_status(:not_found)
      parsed = JSON.parse(response.body)
      expect(parsed["status"]).to eq("404")
    end

    it "renders not found for XML" do
      get solr_document_path(bad_id, format: :xml)
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("<status>404</status>")
      expect(response.body).to include("<error>")
    end

    it "renders not found for HTML" do
      get solr_document_path(bad_id, format: :html)
      expect(response).to have_http_status(:not_found)
      expect(response).to render_template("errors/not_found")
    end
  end
end
