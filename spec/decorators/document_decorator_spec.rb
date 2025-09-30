# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocumentDecorator do
  let(:document) { double("document", id: "test_123") }
  let(:decorated_document) { described_class.new(document) }

  describe "#library_link_url" do
    it "returns the configured library link URL" do
      allow(Rails.configuration).to receive(:library_link).and_return("https://library.temple.edu")
      expect(decorated_document.library_link_url).to eq("https://library.temple.edu")
    end
  end

  describe "#formatted_id" do
    it "returns the document ID with doc- prefix" do
      expect(decorated_document.formatted_id).to eq("doc-test_123")
    end
  end

  describe "#redirect_url" do
    it "returns a redirect URL with the formatted ID as fragment" do
      request_url = "http://example.com/catalog"
      expected_url = Rails.application.routes.url_helpers.new_user_session_path(
        redirect_to: "#{request_url}#doc-test_123"
      )
      expect(decorated_document.redirect_url(request_url)).to eq(expected_url)
    end
  end

  describe ".doc_id" do
    it "returns the ID with doc- prefix" do
      expect(described_class.doc_id("test_123")).to eq("doc-test_123")
    end
  end

  describe ".doc_redirect_url" do
    it "returns a redirect URL for the given ID and request URL" do
      request_url = "http://example.com/catalog"
      expected_url = Rails.application.routes.url_helpers.new_user_session_path(
        redirect_to: "#{request_url}#doc-test_123"
      )
      expect(described_class.doc_redirect_url("test_123", request_url)).to eq(expected_url)
    end
  end

  describe "delegation" do
    it "delegates methods to the wrapped document" do
      expect(decorated_document.id).to eq("test_123")
    end
  end

  # Tests for document data processing methods
  describe "#isbn_data_attribute" do
    let(:document) { SolrDocument.new(data) }
    let(:decorated_doc) { described_class.new(document) }

    context "document contains an isbn" do
      let(:data) { { isbn_display: ["123456789"] } }
      it "returns the data-isbn string" do
        expect(decorated_doc.isbn_data_attribute).to eql "data-isbn=123456789"
      end
    end

    context "document contains multiple isbn" do
      let(:data) { { isbn_display: ["23445667890", "123456789"] } }
      it "returns the data-isbn string" do
        expect(decorated_doc.isbn_data_attribute).to eql "data-isbn=23445667890,123456789"
      end
    end

    context "document does not contain an isbn" do
      let(:data) { {} }
      it "does not return the data-isbn string" do
        expect(decorated_doc.isbn_data_attribute).to be_nil
      end
    end
  end

  describe "#oclc_data_attribute" do
    let(:document) { SolrDocument.new(data) }
    let(:decorated_doc) { described_class.new(document) }

    context "document contains an oclc number" do
      let(:data) { { oclc_number_display: ["123456789"] } }
      it "returns the data-oclc string" do
        expect(decorated_doc.oclc_data_attribute).to eql "data-oclc=123456789"
      end
    end

    context "document contains multiple oclc numbers" do
      let(:data) { { oclc_number_display: ["23445667890", "123456789"] } }
      it "returns the data-oclc string" do
        expect(decorated_doc.oclc_data_attribute).to eql "data-oclc=23445667890,123456789"
      end
    end

    context "document does not contain an oclc number" do
      let(:data) { {} }
      it "does not return the data-oclc string" do
        expect(decorated_doc.oclc_data_attribute).to be_nil
      end
    end
  end

  describe "#lccn_data_attribute" do
    let(:document) { SolrDocument.new(data) }
    let(:decorated_doc) { described_class.new(document) }

    context "document contains an lccn" do
      let(:data) { { lccn_display: ["sn#00061556"] } }
      it "returns the data-lccn string" do
        expect(decorated_doc.lccn_data_attribute).to eql "data-lccn=sn#00061556"
      end
    end

    context "document contains multiple lccn values" do
      let(:data) { { lccn_display: ["sn#00061556", "abc123"] } }
      it "returns the data-lccn string" do
        expect(decorated_doc.lccn_data_attribute).to eql "data-lccn=sn#00061556,abc123"
      end
    end

    context "document does not contain an lccn" do
      let(:data) { {} }
      it "does not return the data-lccn string" do
        expect(decorated_doc.lccn_data_attribute).to be_nil
      end
    end
  end

  describe "#default_cover_image" do
    let(:document) { SolrDocument.new(data) }
    let(:decorated_doc) { described_class.new(document) }

    context "document has a format" do
      let(:data) { { format: ["Book"] } }
      it "returns the appropriate cover image path" do
        expect(decorated_doc.default_cover_image).to eql "svg/book.svg"
      end
    end

    context "document has no format" do
      let(:data) { {} }
      it "returns the unknown cover image path" do
        expect(decorated_doc.default_cover_image).to eql "svg/unknown.svg"
      end
    end

    context "document has a mapped format" do
      let(:data) { { format: ["Article"] } }
      it "returns the mapped cover image path" do
        expect(decorated_doc.default_cover_image).to eql "svg/journal_periodical.svg"
      end
    end
  end

  describe "#field_joiner" do
    let(:document) { SolrDocument.new("test" => value) }
    let(:decorated_doc) { described_class.new(document) }

    context "the field value is empty" do
      let(:value) { "" }
      it "returns an empty string" do
        expect(decorated_doc.field_joiner("test")).to eql ""
      end
    end

    context "the field value is nil" do
      let(:value) { nil }
      it "returns an empty string" do
        expect(decorated_doc.field_joiner("test")).to eql ""
      end
    end

    context "the field value is non empty string value" do
      let(:value) { "an id" }
      it "returns the string value" do
        expect(decorated_doc.field_joiner("test")).to eql "an id"
      end
    end

    context "the field value is an empty array" do
      let(:value) { [] }
      it "returns an empty string" do
        expect(decorated_doc.field_joiner("test")).to eql ""
      end
    end

    context "the field value is an array with a single string value" do
      let(:value) { ["one value"] }
      it "returns the single value" do
        expect(decorated_doc.field_joiner("test")).to eql "one value"
      end
    end

    context "the field value is an array with a single integer value" do
      let(:value) { [3] }
      it "returns the integer as string" do
        expect(decorated_doc.field_joiner("test")).to eql "3"
      end
    end

    context "the field value is an array with multiple string values" do
      let(:value) { ["one", "two"] }
      it "returns the joined values" do
        expect(decorated_doc.field_joiner("test")).to eql "one, two"
      end
    end

    context "with custom joiner" do
      let(:value) { ["one", "two", "three"] }
      it "uses the custom joiner" do
        expect(decorated_doc.field_joiner("test", " | ")).to eql "one | two | three"
      end
    end
  end

  describe "#separate_formats" do
    let(:document) { SolrDocument.new(data) }
    let(:decorated_doc) { described_class.new(document) }

    context "document has single format" do
      let(:data) { { format: ["Book"] } }
      it "returns formatted HTML span" do
        result = decorated_doc.separate_formats
        expect(result).to include("<span class='book'> Book</span>")
        expect(result).to be_html_safe
      end
    end

    context "document has multiple formats" do
      let(:data) { { format: ["Book", "Digital"] } }
      it "returns formatted HTML spans joined with br tags" do
        result = decorated_doc.separate_formats
        expect(result).to include("<span class='book'> Book</span>")
        expect(result).to include("<span class='digital'> Digital</span>")
        expect(result).to include("<br />")
        expect(result).to be_html_safe
      end
    end

    context "document has no formats" do
      let(:data) { {} }
      it "returns empty string" do
        expect(decorated_doc.separate_formats).to eql ""
      end
    end

    context "document has format with special characters" do
      let(:data) { { format: ["<script>alert('xss')</script>"] } }
      it "escapes HTML in format names" do
        result = decorated_doc.separate_formats
        expect(result).not_to include("<script>")
        expect(result).to include("&lt;script&gt;")
      end
    end
  end
end
