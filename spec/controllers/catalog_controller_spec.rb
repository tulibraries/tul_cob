require 'rails_helper'

RSpec.describe CatalogController, type: :controller do
  describe "GET index as json" do
    render_views
    before do
      get(:index, params: {q: "education"}, :format => :json)
    end
    let(:docs) { JSON.parse(response.body)["response"]["docs"] }
    let(:single_doc) { docs.first }
    let(:doc_keys) { single_doc.keys}
    let(:expected_keys) {
      %w[ id
          imprint_display
          creator_display
          pub_date

        ]
    }

    context 'an individual record' do
      it 'has an the expected fields' do
        expect(doc_keys).to include(*expected_keys)
      end


  let(:doc_id) { "991012041239703811" }
  let(:mock_response) { instance_double(Blacklight::Solr::Response) }
  let(:mock_document) { instance_double(SolrDocument) }

  describe "show action" do
    it "gets the staff_view_path" do
      get :show, params: { id: doc_id }
      expect(staff_view_path).to eq("/catalog/#{doc_id}/staff_view")
    end

    it "is properly routed for staff_view" do
      expect(get: "/catalog/:id/staff_view").to route_to(controller: "catalog", action: "librarian_view", id: ":id")
    end
  end
end
