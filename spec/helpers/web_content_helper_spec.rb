# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebContentHelper, type: :helper do
  describe "#solr_web_content_document_path(document, options = {})" do
    context "document has a web_base_url_display field" do
      let(:document) { { "web_base_url_display" => ["https://sites.temple.edu/librarynews/"] } }

      it "links to the base_url" do
        expect(helper.solr_web_content_document_path(document, options = {})).to eq(["https://sites.temple.edu/librarynews/"])
      end
    end

    context "document has a web_link_display field" do
      let(:document) { { "web_link_display" =>
        ["https://www.visitphilly.com/articles/philadelphia/guide-to-tree-lighting-celebrations-in-philadelphia-and-the-countryside/"] } }

      it "links to the base_url" do
        expect(helper.solr_web_content_document_path(document, options = {})).to eq(["https://www.visitphilly.com/articles/philadelphia/guide-to-tree-lighting-celebrations-in-philadelphia-and-the-countryside/"])
      end
    end
  end

  describe "#capitalize_types(type)" do
    let(:type) { "person" }

    it "renders the type with a capital letter" do
      expect(helper.capitalize_types(type)).to eq("Person")
    end
  end
end
