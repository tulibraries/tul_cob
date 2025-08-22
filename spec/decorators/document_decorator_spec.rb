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
end
