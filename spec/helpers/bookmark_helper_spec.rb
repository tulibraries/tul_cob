# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookmarkHelper, type: :helper do
  describe "#index_controller" do
    context "no document or counter provided" do
      it "returns nil" do
        expect(helper.index_controller()).to be_nil
      end
    end

    context "document that does not have ajax? method" do
      it "returns nil" do
        doc = SolrDocument.new({}, nil)
        expect(helper.index_controller(doc)).to be_nil
      end
    end

    context "document that does have solr ajax and is not ajax ready" do
      it "returns nil" do
        doc = PrimoCentralDocument.new({ "ajax" => false }, nil)
        expect(helper.index_controller(doc)).to be_nil
      end
    end

    context "document is ajax ready" do
      doc = PrimoCentralDocument.new({ "pnxId" => "0", "ajax" => true }, nil)

      it "returns string that sets stimulus controller and data attributes" do
        expected = "data-controller=index data-index-url=/articles/0/index_item?document_counter=0"
        expect(helper.index_controller(doc)).to eq(expected)
      end

      it "correctly sets the document counter if pased" do
        expected = "data-controller=index data-index-url=/articles/0/index_item?document_counter=1"
        expect(helper.index_controller(doc, 1)).to eq(expected)
      end
    end
  end
end
