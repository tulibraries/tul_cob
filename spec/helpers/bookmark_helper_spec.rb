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

    describe "#render_article_bookmark_export_button" do
      context "no documents" do
        it "returns nil" do
          expect(helper.render_article_bookmark_export_button([])).to be_nil
        end
      end

      context "no article documents" do
        doc = SolrDocument.new(id: "foo")
        docs = [doc]

        it "returns nil" do
          expect(helper.render_article_bookmark_export_button(docs)).to be_nil
        end
      end

      context "article documents present" do
        doc_a = SolrDocument.new(id: "foo")
        doc_b = PrimoCentralDocument.new({})
        docs = [doc_a, doc_b]

        it "returns an html button wrapped in list item tag" do
          link = "<li><a id=\"exportArticleBookmarks\" class=\"clear-bookmarks btn btn-sm btn-danger\" href=\"/bookmarks/export/articles\">Export Article Bookmarks</a></li>"

          expect(helper.render_article_bookmark_export_button(docs)).to eq(link)
        end
      end
    end
  end
end
