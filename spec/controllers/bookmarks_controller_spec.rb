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
    render_views

    let(:documents) do
      (1..11).map do |i|
        document = SolrDocument.new(
          "id" => i.to_s,
          "title_statement_display" => ["Title #{i}"],
          "creator_display" => ["Author #{i}"],
          "contributor_display" => ["Contributor #{i}"],
          "imprint_display" => ["Imprint #{i}"],
          "isbn_display" => ["ISBN #{i}"]
        )
        allow(document).to receive(:document_items_grouped).and_return(
          { "Main Library" => { "Stacks" => [{ "call_number_display" => "CN #{i}" }] } }
        )
        document
      end
    end
    let(:response_double) { instance_double(Blacklight::Solr::Response, documents: documents, export_formats: [:csv]) }
    let(:bookmarks) do
      (1..11).map do |i|
        Bookmark.new(document_id: i.to_s, document_type: SolrDocument.to_s)
      end
    end
    let(:user) { instance_double(User, bookmarks: bookmarks) }
    let(:search_service) { instance_double(Blacklight::SearchService) }

    before do
      allow(controller).to receive(:token_or_current_or_guest_user).and_return(user)
      allow(controller).to receive(:current_or_guest_user).and_return(user)
      allow(controller).to receive(:search_service).and_return(search_service)
      allow(controller).to receive(:bookmark_ids_for_csv).and_return((1..11).map(&:to_s))
    end

    it "returns a CSV with headers and a row per document" do
      expected_filter = "{!terms f=id}#{(1..11).map(&:to_s).join(',')}"
      repository = instance_double(Blacklight::Solr::Repository)

      allow(search_service).to receive(:repository).and_return(repository)
      allow(response_double).to receive(:documents).and_return(documents)
      expect(repository).to receive(:search)
        .with(q: "*:*", fq: expected_filter, rows: 11)
        .and_return(response_double)
      get :index, params: { format: "csv" }

      rows = CSV.parse(response.body, skip_blanks: true)
      expect(rows.length).to eq(12), "CSV rows were: #{rows.inspect}"
      expect(rows[0]).to eq(CsvExportable::HEADERS)
      expect(rows[1]).to eq(["Title 1", "Imprint 1", "Author 1", "Contributor 1", "ISBN 1", "Main Library - Stacks - CN 1", "https://librarysearch.temple.edu/catalog/1"])
      expect(rows[11]).to eq(["Title 11", "Imprint 11", "Author 11", "Contributor 11", "ISBN 11", "Main Library - Stacks - CN 11", "https://librarysearch.temple.edu/catalog/11"])
      expect(response.media_type).to eq("text/csv")
    end

    it "uses bookmark_ids_for_csv to build the CSV" do
      repository = instance_double(Blacklight::Solr::Repository)
      response_double = instance_double(Blacklight::Solr::Response, documents: documents)
      allow(search_service).to receive(:repository).and_return(repository)
      expect(repository).to receive(:search)
        .with(q: "*:*", fq: "{!terms f=id}#{(1..11).map(&:to_s).join(',')}", rows: 11)
        .and_return(response_double)

      get :index, params: { format: "csv" }

      rows = CSV.parse(response.body, skip_blanks: true)
      expect(rows[1]).to eq(["Title 1", "Imprint 1", "Author 1", "Contributor 1", "ISBN 1", "Main Library - Stacks - CN 1", "https://librarysearch.temple.edu/catalog/1"])
    end
  end

  describe "#create" do
    let(:bookmarks_relation) { instance_double(ActiveRecord::Relation) }
    let(:user) { instance_double(User, persisted?: true, bookmarks: bookmarks_relation) }
    let(:submitted_bookmarks) do
      [
        { document_id: "1", document_type: "SolrDocument" },
        { document_id: "2", document_type: "SolrDocument" }
      ]
    end

    before do
      allow(controller).to receive(:current_or_guest_user).and_return(user)
      allow(controller).to receive(:current_user).and_return(User.new)
      allow(controller).to receive(:permit_bookmarks).and_return({ bookmarks: submitted_bookmarks })
      allow(request).to receive(:xhr?).and_return(false)
    end

    it "uses the actual number of inserted rows in the success message" do
      allow(bookmarks_relation).to receive(:where)
        .with(document_type: "SolrDocument", document_id: %w[1 2])
        .and_return(bookmarks_relation)
      allow(bookmarks_relation).to receive(:pluck).with(:document_id).and_return(["1"])
      expect(bookmarks_relation).to receive(:create!)
        .with([{ document_id: "2", document_type: "SolrDocument" }])
      post :create, params: { bookmarks: submitted_bookmarks }

      expect(flash[:notice]).to eq(I18n.t("blacklight.bookmarks.add.success", count: 1))
    end
  end

  describe "#destroy" do
    let(:bookmarks_relation) { instance_double(ActiveRecord::Relation) }
    let(:matching_bookmarks) { instance_double(ActiveRecord::Relation) }
    let(:user) { instance_double(User, bookmarks: bookmarks_relation) }
    let(:submitted_bookmarks) do
      [
        { document_id: "1", document_type: "SolrDocument" },
        { document_id: "2", document_type: "SolrDocument" }
      ]
    end

    before do
      allow(controller).to receive(:current_or_guest_user).and_return(user)
      allow(controller).to receive(:current_user).and_return(User.new)
      allow(controller).to receive(:permit_bookmarks).and_return({ bookmarks: submitted_bookmarks })
      allow(request).to receive(:xhr?).and_return(false)
    end

    it "removes all requested bookmarks for batch unbookmark requests" do
      allow(bookmarks_relation).to receive(:where)
        .with(document_type: "SolrDocument", document_id: %w[1 2])
        .and_return(matching_bookmarks)
      expect(matching_bookmarks).to receive(:delete_all).and_return(2)
      delete :destroy, params: { id: "1", bookmarks: submitted_bookmarks }

      expect(flash[:notice]).to eq(I18n.t("blacklight.bookmarks.remove.success", count: 2))
    end
  end

  describe "#set_guest_bookmark_warning" do
    it "sets an alert for guests on non-xhr requests" do
      allow(controller).to receive(:current_user).and_return(nil)
      allow(request).to receive(:xhr?).and_return(false)

      controller.send(:set_guest_bookmark_warning)

      expect(flash[:alert]).to eq(I18n.t("blacklight.bookmarks.need_login"))
    end

    it "does not set an alert for xhr requests" do
      allow(controller).to receive(:current_user).and_return(nil)
      allow(request).to receive(:xhr?).and_return(true)

      controller.send(:set_guest_bookmark_warning)

      expect(flash[:alert]).to be_nil
    end

    it "does not set an alert for logged-in users" do
      allow(controller).to receive(:current_user).and_return(User.new)
      allow(request).to receive(:xhr?).and_return(false)

      controller.send(:set_guest_bookmark_warning)

      expect(flash[:alert]).to be_nil
    end
  end

end
