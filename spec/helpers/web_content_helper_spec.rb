# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebContentHelper, type: :helper do
  describe "#solr_web_content_document_path(document, options = {})" do
    context "document has a web_url_display field" do
      let(:document) { { "web_url_display" => ["https://library.temple.edu/about/staff?f%5B0%5D=taxonomy_vocabulary_2%3A1038"] } }

      it "links to the url" do
        expect(helper.solr_web_content_document_path(document, options = {})).to eq(["https://library.temple.edu/about/staff?f%5B0%5D=taxonomy_vocabulary_2%3A1038"])
      end
    end
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

  describe "#format_types(type)" do
    let(:type) { "service" }

    it "renders the plural form of the type" do
      expect(helper.format_types(type)).to eq("Services")
    end

    it "renders the type with a capital letter" do
      expect(helper.format_types(type)).to eq("Services")
    end
  end

  describe "#capitalize_type(document)" do
    let(:document) { { value: ["service"] } }

    it "renders the type with a capital letter" do
      expect(helper.capitalize_type(document)).to eq("Service")
    end
  end

  describe "#format_phone_number(document)" do
    let(:document) { { value: ["2152048384"] } }

    it "renders the type with a capital letter" do
      expect(helper.format_phone_number(document)).to eq("215-204-8384")
    end
  end

  describe "#website_list(document)" do
    let(:document) { { value: ["[Immigrant-Ethnic Communities, Politics and Protest, Women]"] } }

    it "displays results as a list of items" do
      expect(helper.website_list(document)).to eq("<li class=\"list_items\">Immigrant-Ethnic Communities</li><li class=\"list_items\"> Politics and Protest</li><li class=\"list_items\"> Women</li>")
    end
  end
end
