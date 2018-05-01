# frozen_string_literal: true

require "rails_helper"
include ERB::Util

RSpec.describe PrimoCentralHelper, type: :helper do
  let(:doc) { Hash.new }
  let(:document) { PrimoCentralDocument.new(doc) }
  let(:base_path) { "" }

  before(:example) do
    allow(helper).to receive(:base_path).and_return("")
    @document = document
  end

  describe "#availability_link_partials" do
    context "document does not have a direct link" do
      it "returns only the online partial" do
        expect(availability_link_partials).to eq(["online"])
      end
    end

    context "document does have a direct link" do
      let(:doc) { ActiveSupport::HashWithIndifferentAccess.new(
        delivery: { availability: ["fulltext_linktorsrc"] }
      )}

      it "returns only the direc_link partial" do
        expect(availability_link_partials).to eq(["direct_link"])
      end
    end
  end

  describe "#index_buttons_partials" do
    context "document does not have a direct link" do
      it "returns only the online button partial" do
        expect(index_buttons_partials).to eq(["online_button"])
      end
    end

    context "document does have a direct link" do
      let(:doc) { ActiveSupport::HashWithIndifferentAccess.new(
        delivery: { availability: ["fulltext_linktorsrc"] }
      )}

      it "returns only the direc_link button partial" do
        expect(index_buttons_partials).to eq(["direct_link_button"])
      end
    end
  end

  describe "#document_link_label" do
    context "no link label found" do
      it "returns a default value when no direct link label is found" do
        expect(document_link_label).to eq("Link to Resource")
      end
    end
  end

  describe "#browse_creator" do
    context "no creator" do
      let(:presenter) { { document: document, field: "creator" } }
      it "returns an empty list if nos creators are available" do
        expect(browse_creator(presenter)).to eq([])
      end
    end

    context "a creator" do
      let(:doc) { ActiveSupport::HashWithIndifferentAccess.new(
        creator: ["Hello, World"],
      )}
      let(:presenter) { { document: document, field: "creator" } }
      it "returns a list of links to creator search for each creator" do
        expect(browse_creator(presenter)).to eq([
          "<a href=\"?search_field=creator&amp;q=Hello%2C%20World\">Hello, World</a>",
        ])
      end
    end

  end
end
