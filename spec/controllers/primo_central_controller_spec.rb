# frozen_string_literal: true

require "rails_helper"


RSpec.describe PrimoCentralController, type: :controller do
  let(:doc) { Hash.new }
  let(:document) { PrimoCentralDocument.new(doc) }
  let(:helpers) { double("helper", base_path: "/") }
  let(:mock_response) { instance_double(Blacklight::PrimoCentral::Response) }

  before(:each) do
    allow(controller).to receive(:helpers).and_return(helpers)
    allow(controller).to receive_messages fetch: [mock_response, document]
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
    it "gets refwork format" do
      get :show, params: { id: 1, format: "refworks" }
      expect(response).to be_success
    end
  end
end
