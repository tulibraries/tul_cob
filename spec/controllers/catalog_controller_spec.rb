# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatalogController, type: :controller do

  let(:doc_id) { "991012041239703811" }
  let(:mock_response) { instance_double(Blacklight::Solr::Response) }
  let(:mock_document) { instance_double(SolrDocument) }

  describe "show action" do
    it "gets the staff_view_title" do
      get :show, params: { id: doc_id }
      expect(assigns[:staff_view_title]).to eq("Staff View")
    end

    it "gets the staff_view_path" do
      get :show, params: { id: doc_id }
      expect(staff_view_path).to eq("/catalog/#{doc_id}/staff_view")
    end

    it "is properly routed for staff_view" do
      expect(get: "/catalog/:id/staff_view").to route_to(controller: "catalog", action: "librarian_view", id: ":id")
    end
  end

  describe "librarian_view action" do
    it "gets the marc_view" do
      get :librarian_view, params: { id: doc_id }
      expect(assigns[:marc_view]).to_not be_nil
    end
  end
end
