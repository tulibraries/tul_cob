# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrimoCentralHelper, type: :helper do
  let(:doc) { Hash.new }
  let(:document) { PrimoCentralDocument.new(doc) }
  before(:example) do
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
        expect(document_link_label).to eq("Direct Link")
      end
    end

    context "link label available" do
      let(:doc) { ActiveSupport::HashWithIndifferentAccess.new(
        delivery: {
          GetIt1: [{
            "links" => [{ "displayText" => "$$EView_full_text_via_AgEcon" }],
          }] }) }
      it "correctly normalized label if found" do
        expect(document_link_label).to eq("View full text via AgEcon")
      end
    end
  end
end
