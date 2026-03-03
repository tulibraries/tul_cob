# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Catalog track with stale search/session state", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:doc_id) { "991034781679703811" }
  let(:solr_response) { instance_double(Blacklight::Solr::Response, total: 1, more_like: [], :[] => {}) }
  let(:solr_document) { SolrDocument.new({ "id" => doc_id }, solr_response) }

  describe "current behavior guardrail" do
    it "redirects from track even with stale search_id" do
      allow_any_instance_of(Blacklight::SearchService)
        .to receive(:fetch)
        .and_return([solr_response, solr_document])

      post "/catalog/#{doc_id}/track", params: {
        counter: "98",
        document_id: doc_id,
        search_id: "999999999",
        per_page: "10"
      }

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to("/catalog/#{doc_id}")
    end
  end

  describe "BL-2006 regression (red spec)" do
    it "does not 500 when show is requested after tracked search context is deleted" do
      allow_any_instance_of(Blacklight::SearchService)
        .to receive(:fetch)
        .and_return([solr_response, solr_document])

      search = Search.create!(query_params: { q: "remediation" })

      post "/catalog/#{doc_id}/track", params: {
        counter: "98",
        document_id: doc_id,
        search_id: search.id,
        per_page: "10"
      }

      search.destroy!

      get "/catalog/#{doc_id}"

      # Intentional red spec: this should become non-500 after the fix.
      expect(response).to have_http_status(:ok)
    end
  end
end
