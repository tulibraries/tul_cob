# frozen_string_literal: true

require "rails_helper"

RSpec.describe "parameter boundaries", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { FactoryBot.create(:user) }

  describe "bookmark creation" do
    it "persists only the permitted nested bookmark fields" do
      sign_in user

      expect {
        post bookmarks_path,
          params: {
            bookmarks: [
              {
                document_id: "book-1",
                document_type: "SolrDocument",
                unexpected: "ignored"
              }
            ],
            unexpected: "ignored"
          },
          headers: { "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest" }
      }.to change { user.bookmarks.count }.by(1)

      expect(response).to have_http_status(:ok)
      bookmark = user.bookmarks.find_by(document_id: "book-1")
      expect(bookmark.document_type.to_s).to eq("SolrDocument")
    end
  end

  describe "loan renewal" do
    it "passes only the permitted loan id array to the renewal workflow" do
      sign_in user
      renewed_ids = nil
      allow_any_instance_of(User).to receive(:renew_selected) do |_user, loan_ids|
        renewed_ids = loan_ids
        []
      end

      post "/users/renew_selected",
        params: {
          loan_ids: %w[loan-1 loan-2],
          unexpected: "ignored"
        },
        as: :json

      expect(response).to have_http_status(:ok)
      expect(renewed_ids).to eq(%w[loan-1 loan-2])
    end
  end

  describe "Alma hold requests" do
    it "permits the material type value but drops unexpected nested data" do
      sign_in user
      submitted_options = nil
      response_double = instance_double("Alma::BibRequestResponse", loggable: {})
      confirmation = instance_double(RequestConfirmation, message: "success")

      allow(Alma::BibRequest).to receive(:submit) do |options|
        submitted_options = options
        response_double
      end
      allow(RequestConfirmation).to receive(:new).and_return(confirmation)

      post hold_request_path,
        params: {
          mms_id: "",
          material_type: { value: "BOOK", unexpected: "ignored" },
          unexpected: "ignored"
        },
        headers: { "HTTP_REFERER" => root_path }

      expect(response).to redirect_to(root_path)
      expect(submitted_options[:material_type]).to eq(value: "BOOK")
      expect(submitted_options).not_to have_key(:unexpected)
    end
  end

  describe "LibGuides search" do
    it "passes the permitted query and ignores unrelated request data" do
      allow(LibGuidesApi).to receive(:fetch).and_return([])

      get lib_guides_path, params: { q: "catalog", unexpected: "ignored" }

      expect(response).to have_http_status(:ok)
      expect(LibGuidesApi).to have_received(:fetch).with("catalog")
    end
  end

  describe "facet search" do
    it "preserves facet pagination and searching within a facet" do
      facet = Blacklight::Solr::Response::Facets::FacetField.new(
        "creator_facet",
        [ Blacklight::Solr::Response::Facets::FacetItem.new("rare", 1) ],
        offset: 10
      )
      response_double = instance_double(
        Blacklight::Solr::Response,
        aggregations: { "creator_facet" => facet }
      )
      service = instance_double(Blacklight::SearchService, facet_suggest_response: response_double)
      allow_any_instance_of(CatalogController).to receive(:search_service).and_return(service)

      get facet_catalog_path(id: "creator_facet"), params: {
        "facet.page" => "2",
        query_fragment: "rare",
        only_values: "true",
        unexpected: "ignored",
        format: :json
      }

      expect(response).to have_http_status(:ok)
      expect(controller.send(:search_state).params).to include(
        "facet.page" => "2",
        query_fragment: "rare",
        only_values: "true"
      )
      expect(controller.send(:search_state).params).not_to have_key(:unexpected)
      expect(service).to have_received(:facet_suggest_response).with("creator_facet", "rare")
    end
  end

  describe "emailing records" do
    it "accepts an ID array and message without forwarding unexpected parameters" do
      sign_in user
      documents = [ instance_double(SolrDocument), instance_double(SolrDocument) ]
      service = instance_double(Blacklight::SearchService, fetch: documents)
      mail = instance_double(ActionMailer::MessageDelivery, deliver_now: true)
      allow_any_instance_of(CatalogController).to receive(:search_service).and_return(service)
      allow(RecordMailer).to receive(:email_record).and_return(mail)

      post email_solr_documents_path, params: {
        id: %w[record-1 record-2],
        to: "reader@example.edu",
        message: "Please review these records.",
        unexpected: "ignored"
      }

      expect(response).to have_http_status(:redirect)
      expect(service).to have_received(:fetch).with(%w[record-1 record-2])
      expect(RecordMailer).to have_received(:email_record).with(
        documents,
        hash_including(to: "reader@example.edu", message: "Please review these records."),
        anything
      )
    end

    it "supports the inherited bookmarks email action" do
      sign_in user
      documents = [ instance_double(SolrDocument), instance_double(SolrDocument) ]
      service = instance_double(Blacklight::SearchService)
      mail = instance_double(ActionMailer::MessageDelivery, deliver_now: true)
      allow_any_instance_of(BookmarksController).to receive(:search_service).and_return(service)
      allow(service).to receive(:fetch).with(%w[record-1 record-2], rows: 2, start: 0).and_return(documents)
      allow(RecordMailer).to receive(:email_record).and_return(mail)

      post email_bookmarks_path, params: {
        id: %w[record-1 record-2],
        to: "reader@example.edu",
        message: "Please review these bookmarks.",
        unexpected: "ignored"
      }

      expect(response).to have_http_status(:redirect)
      expect(RecordMailer).to have_received(:email_record).with(
        documents,
        hash_including(to: "reader@example.edu", message: "Please review these bookmarks."),
        anything
      )
    end
  end

  describe "citation requests" do
    it "retrieves the cited record without action-specific permitted parameters" do
      document = SolrDocument.new(
        "id" => "record-1",
        "title_statement_display" => ["Example Book Title"],
        "creator_display" => ["Doe, Jane"],
        "pub_date_display" => ["2020"],
        "format" => ["Book"]
      )
      allow(Flipflop).to receive(:citeproc_citations?).and_return(true)
      allow_any_instance_of(CatalogController).to receive(:retrieve_documents)
        .with(["record-1"])
        .and_return([document])

      get citation_solr_document_path(id: "record-1")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Example Book Title")
    end
  end

  describe "advanced search" do
    before do
      response_double = Blacklight::Solr::Response.new(
        { "response" => { "docs" => [], "numFound" => 0 } },
        {},
        blacklight_config: CatalogController.blacklight_config
      )
      service = instance_double(Blacklight::SearchService, search_results: response_double)
      allow_any_instance_of(CatalogController).to receive(:search_service).and_return(service)
    end

    it "accepts the configured maximum number of clauses" do
      get search_catalog_path, params: { search_field: "advanced", q_10: "tenth clause" }

      expect(response).not_to have_http_status(:bad_request)
    end

    it "rejects an over-limit advanced search instead of silently dropping clauses" do
      get search_catalog_path, params: { search_field: "advanced", q_11: "eleventh clause" }

      expect(response).to have_http_status(:bad_request)
      expect(response.body).to include("Too many advanced search clauses")
    end
  end

  describe "tokenized bookmarks" do
    it "preserves the encrypted owner token without an owner session" do
      token = encrypted_user_token(user.id)
      response_double = Blacklight::Solr::Response.new(
        { "response" => { "docs" => [] } },
        {},
        blacklight_config: BookmarksController.blacklight_config
      )
      service = instance_double(Blacklight::SearchService, search_results: response_double)
      allow_any_instance_of(BookmarksController).to receive(:search_service).and_return(service)

      get bookmarks_path, params: { encrypted_user_id: token, unexpected: "ignored" }

      expect(response).to have_http_status(:ok)
      expect(response).not_to redirect_to(new_user_session_path)
      expect(controller.send(:token_or_current_or_guest_user)).to eq(user)
    end
  end

  describe "related-title query lists" do
    it "passes filter_id through to the Solr exclusion filter" do
      solr_parameters = nil
      response_double = Blacklight::Solr::Response.new(
        { "response" => { "docs" => [] } },
        {}
      )
      allow_any_instance_of(Blacklight::Solr::Repository).to receive(:search) do |_repository, params:|
        solr_parameters = params.to_h
        response_double
      end

      get query_list_path, params: {
        q: "related",
        filter_id: "record-1",
        footer_field: "title"
      }

      expect(response).to have_http_status(:ok)
      expect(solr_parameters["fq"]).to include("-id:record-1")
    end
  end

  private

    def encrypted_user_token(user_id)
      key_generator = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base)
      secret = key_generator.generate_key("encrypted user session key", ActiveSupport::MessageEncryptor.key_len)
      encryptor = ActiveSupport::MessageEncryptor.new(secret)
      encryptor.encrypt_and_sign([user_id, Time.zone.now])
    end
end
