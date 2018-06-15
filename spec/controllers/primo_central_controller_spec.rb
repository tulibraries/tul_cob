# frozen_string_literal: true

require "rails_helper"


RSpec.describe PrimoCentralController, type: :controller do
  let(:doc) { Hash.new }
  let(:document) { PrimoCentralDocument.new(doc) }
  let(:helpers) { double("helper", base_path: "/") }

  before(:each) do
    allow(controller).to receive(:helpers).and_return(helpers)
  end

  describe "#browse_creator" do
    context "no creator" do
      let(:presenter) { { document: document, field: "creator" } }
      it "returns an empty list if nos creators are available" do
        expect(controller.browse_creator(presenter)).to eq(0)
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
end
