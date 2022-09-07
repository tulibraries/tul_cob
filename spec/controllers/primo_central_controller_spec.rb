# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrimoCentralController, type: :controller do
  let(:doc) { Hash.new }
  let(:options) { { blacklight_config: controller.blacklight_config } }
  let(:document) { PrimoCentralDocument.new(doc, options) }
  let(:helpers) { double("helper", base_path: "/") }
  let(:mock_response) { instance_double(Blacklight::PrimoCentral::Response) }
  let(:search_service) { instance_double(Blacklight::SearchService) }

  before(:each) do
    allow(controller).to receive(:helpers).and_return(helpers)
    allow(controller).to receive(:search_service).and_return(search_service)
    allow(search_service).to receive(:fetch).and_return([mock_response, document])
    allow(search_service).to receive(:search_results).and_return([mock_response, document])
  end

  describe "#browse_creator" do
    context "no creator" do
      let(:presenter) { { document: document, field: "creator" } }
      it "returns an empty list if nos creators are available" do
        expect(controller.browse_creator(presenter)).to eq([])
      end
    end

    context "a creator" do
      let(:doc) { ActiveSupport::HashWithIndifferentAccess.new(
        creator: ["Hello, World"],
      )}
      let(:presenter) { { document: document, field: "creator" } }
      it "returns a list of links to creator search for each creator" do
        expect(controller.browse_creator(presenter)).to eq([
          "<a href=\"/?search_field=creator&amp;q=Hello%2C%20World\">Hello, World</a>",
        ])
      end
    end
  end

  describe "show action" do
    render_views

    it "handles a record not found exception", with_rescue: true do
      allow(search_service).to receive(:fetch).and_raise(Primo::Search::ArticleNotFound, "glub glub glub")
      get :show, params: { id: 1 }
      expect(response.code).to eq "404"
      expect(response.body).to include "error-header not-found"
    end
  end

  describe "net_read_timeout_rescue", with_rescue: true do
    before do
      allow(controller).to receive(:index) { raise Net::ReadTimeout }
    end

    context "when timeout happens but no deep pagination" do
      it "rescues from Net::ReadTimeout with a friendly error" do
        get :index

        expect(response).to redirect_to "/articles"
        expect(flash[:error]).to eq("Your search query has timed out.")
      end
    end

    context "when timeout happens and deep pagination is present" do
      it "rescues from Net::ReadTimeout with a friendly error" do
        get :index, params: { page: 50 }

        expect(response).to redirect_to "/articles"
        expect(flash[:error]).to eq("Your search query has timed out. You may have exceeded the maximum number of pages allowed for an Articles search query in Library Search.")
      end
    end

  end
end
