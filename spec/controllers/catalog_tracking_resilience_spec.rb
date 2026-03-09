# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatalogController, type: :controller do
  let(:doc_id) { "991034781679703811" }
  let(:solr_response) { instance_double(Blacklight::Solr::Response, total: 1, more_like: [], :[] => {}) }
  let(:solr_document) { SolrDocument.new({ "id" => doc_id }, solr_response) }
  let(:search_service) { instance_double(Blacklight::SearchService) }

  before do
    allow(search_service).to receive(:fetch).with(doc_id).and_return([solr_response, solr_document])
    allow(controller).to receive(:search_service).and_return(search_service)
  end

  describe "stale search session cleanup" do
    it "clears stale search context keys on show" do
      session[:search] = {
        "id" => "999999999",
        "counter" => "98",
        "per_page" => "10",
        "document_id" => doc_id,
        "total" => "100"
      }

      get :show, params: { id: doc_id }

      expect(response).to have_http_status(:ok)
      expect(session[:search]["id"]).to be_nil
      expect(session[:search]["counter"]).to be_nil
      expect(session[:search]["per_page"]).to be_nil
      expect(session[:search]["document_id"]).to be_nil
      expect(session[:search]["total"]).to be_nil
    end

    it "preserves a valid search session id on show" do
      search = Search.create!(query_params: { q: "otter" })
      session[:search] = { "id" => search.id.to_s }
      allow(controller).to receive(:current_search_session).and_return(search)

      get :show, params: { id: doc_id }

      expect(response).to have_http_status(:ok)
      expect(session[:search]["id"]).to eq(search.id.to_s)
    end
  end

  describe "track action" do
    it "stores tracking params in search session and redirects to show" do
      post :track, params: {
        id: doc_id,
        counter: "98",
        document_id: doc_id,
        search_id: "32170496",
        per_page: "10"
      }

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to("/catalog/#{doc_id}")
      expect(session[:search]["counter"]).to eq("98")
      expect(session[:search]["id"]).to eq("32170496")
      expect(session[:search]["per_page"]).to eq("10")
      expect(session[:search]["document_id"]).to eq(doc_id)
    end
  end
end
