# frozen_string_literal: true

require "rails_helper"
require "csv"

RSpec.describe BookmarksController do
  describe "index" do
    it "does not get cached" do
      get :index

      expect(response.headers["Cache-Control"]).to eq("private, no-store")
      expect(response.headers["Pragma"]).to eq("no-cache")
      expect(response.headers["Expires"]).to eq("Fri, 01 Jan 1990 00:00:00 GMT")
    end
  end

  describe "index csv" do
    let(:document) do
      SolrDocument.new(
        "id" => "123",
        "title_statement_display" => ["The Title"],
        "creator_display" => ["Author One"],
        "call_number_display" => ["ABC 123"]
      )
    end
    let(:response_double) { instance_double(Blacklight::Solr::Response, documents: [document], export_formats: [:csv]) }
    let(:bookmark) { Bookmark.new(document_id: "123", document_type: SolrDocument.to_s) }
    let(:user) { instance_double(User, bookmarks: [bookmark]) }
    let(:search_service) { instance_double(Blacklight::SearchService) }

    before do
      allow(controller).to receive(:token_or_current_or_guest_user).and_return(user)
      allow(controller).to receive(:current_or_guest_user).and_return(user)
      allow(controller).to receive(:search_service).and_return(search_service)
    end

    it "returns a CSV with headers and a row per document" do
      expect(search_service).to receive(:fetch).with(["123"]).and_return([response_double, [document]])
      get :index, params: { format: "csv" }

      rows = CSV.parse(response.body)
      expect(rows[0]).to eq(CsvExportable::HEADERS)
      expect(rows[1]).to eq(["The Title", "Author One", "ABC 123", "https://librarysearch.temple.edu/catalog/123"])
      expect(response.media_type).to eq("text/csv")
    end
  end
end
