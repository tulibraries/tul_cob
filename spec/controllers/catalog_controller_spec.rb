# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatalogController, type: :controller do


  let(:doc_id) { "991012041239703811" }
  let(:mock_response) { instance_double(Blacklight::Solr::Response) }
  let(:mock_document) { instance_double(SolrDocument) }
  let(:search_service) { instance_double(Blacklight::SearchService) }

  describe "show action" do
    it "gets the staff_view_path" do
      get :show, params: { id: doc_id }
      expect(staff_view_path).to eq("/catalog/#{doc_id}/staff_view")
    end

    it "is properly routed for staff_view" do
      expect(get: "/catalog/:id/staff_view").to route_to(controller: "catalog", action: "librarian_view", id: ":id")
    end
  end


  describe "GET index as json" do
    render_views
    before do
      get(:index, params: { q: "education" }, format: :json)
    end
    let(:docs) { JSON.parse(response.body)["data"] }
    # Collect the keys from the document hashes into a single array
    let(:docs_keys) { docs.collect { |doc| doc["attributes"].keys }.flatten.uniq }
    let(:expected_keys) {
      %w[ creator_display format ]
    }

    context "an individual index result" do
      it "has an the expected fields" do
        expected_keys.each do |key|
          expect(docs_keys).to include key
        end
      end
    end
  end

  describe "using lower case boolen operators in normal search" do
    render_views
    let(:uppercase_and) { JSON.parse(get(:index, params: { q: "race affirmative action AND higher education" }, format: :json).body)["meta"]["pages"]["total_count"] }
    let(:lowercase_and) { JSON.parse(get(:index, params: { q: "race affirmative action and higher education " }, format: :json).body)["meta"]["pages"]["total_count"] }

    it "returns more results that using uppercase boolean" do
      expect(lowercase_and).to be > uppercase_and
    end
  end

  describe "using & or and produce the same results" do
    render_views
    let(:letters_and) { JSON.parse(get(:index, params: { q: "pride and prejudice" }, format: :json).body)["meta"]["pages"]["total_count"] }
    let(:ampers_and) { JSON.parse(get(:index, params: { q: "pride & prejudice" }, format: :json).body)["meta"]["pages"]["total_count"] }

    it "returns the same number of results" do
      expect(letters_and).to eql ampers_and
    end
  end

  describe "Boundwith Host records should not have been indexed" do
    render_views
    let(:bwh) { JSON.parse(get(:index, params: { q: "22293201420003811" }, format: :json).body)["meta"]["pages"]["total_count"] }

    it "returns no results" do
      expect(bwh).to eql 0
    end
  end

  describe "sms" do
    let(:doc) { SolrDocument.new(id: "my_fake_doc") }

    before do
      allow(search_service).to receive(:fetch).and_return([mock_response, [doc]])
      allow(controller).to receive(:search_service).and_return(search_service)
      allow(doc).to receive(:material_from_barcode) { "CHOSEN BOOK" }
    end

    context "no selection is present" do
      it "does not flash an error" do
        post :sms, params: { id: doc_id, to: "5555555555", carrier: "txt.att.net" } rescue nil

        expect(request.flash[:error]).to be_nil
      end
    end

    context "no selection is made" do
      it "gives an error when no location is selected" do
        post :sms, params: { id: doc_id, to: "5555555555", carrier: "txt.att.net", barcode: nil }

        expect(request.flash[:error]).to eq "You must select a location."
      end
    end

    context "An invalid location is selected" do
      it "gives and error when invalid location is attempted" do
        post :sms, params: {
          id: doc_id, to: "5555555555",
          carrier: "txt.att.net", barcode: "<3 <3 <3" }

        expect(request.flash[:error]).to eq "An invalid location was selected."
      end
    end

    context "A valid location is used" do
      it "does not flash an error and sets the chosen book" do
        allow(doc).to receive(:valid_barcode?) { true }
        post(:sms, params: { id: doc_id, to: "5555555555", carrier: "txt.att.net", barcode: "<3", from: "me" }) rescue nil

        expect(request.flash[:error]).to be_nil
        expect(doc[:sms]).to eq("CHOSEN BOOK")
      end
    end
  end

  describe "#purchase_order/#purchase_order_action" do
    before do
      allow(controller).to receive(:purchase_order_action) {}
    end

    context "user is not logged in" do
      it "does not allow access to purchase order action" do
        get :purchase_order, params: { id: doc_id }
        expect(response).not_to be_successful

        post :purchase_order_action, params: { id: doc_id }
        expect(response).not_to be_successful
      end
    end

    context "user is logged in" do
      let(:user) { FactoryBot.create(:user) }
      let(:allow_purchase) { true }

      before do
        sign_in user
        allow(controller).to receive(:current_user) { user }
        allow(user).to receive(:can_purchase_order?) { allow_purchase }
      end

      context "user group is allowed to purchase order" do
        it "allows access to purchase order action" do
          get :purchase_order, params: { id: doc_id }
          expect(response).to be_successful

          post :purchase_order_action, params: { id: doc_id }
          expect(response).to be_successful
        end
      end

      context "user group is not allowed to purchase order" do
        let(:allow_purchase) { false }

        it "does not allow access to purchase order action" do
          get :purchase_order, params: { id: doc_id }
          expect(response).not_to be_successful

          post :purchase_order_action, params: { id: doc_id }
          expect(response).not_to be_successful
        end
      end
    end
  end

  describe "#do_with_json_logger" do
    before do
      allow(controller).to receive(:json_request_logger) {}
      allow(Time).to receive(:now) { "boo" }
    end

    it "yields the passed in block" do
      expect(controller.do_with_json_logger({}) { "foo" }).to eq("foo")
    end

    it "logs the passed in param with start time" do
      controller.do_with_json_logger(foo: "bar")
      expect(controller).to have_received(:json_request_logger).with(foo: "bar", start: "boo")
    end

    context "passed in block throws an error" do
      it "logs the passed in param plus the error" do
        controller.do_with_json_logger(foo: "bar") { raise StandardError } rescue nil
        expect(controller).to have_received(:json_request_logger).with(foo: "bar", error: "StandardError", start: "boo")
      end
    end

    context "passed in block return response to loggable" do
      it "merges loggable with log" do
        controller.do_with_json_logger(foo: "bar") { OpenStruct.new(loggable: { bizz: "buzz" }) }
        expect(controller).to have_received(:json_request_logger).with(foo: "bar", bizz: "buzz", start: "boo")
      end
    end

    context "raised error message if JSON parsable" do
      it "parses the error message as json and merges to log" do
        message = { error: "foo", bizz: "buzz" }.to_json
        controller.do_with_json_logger(foo: "bar") { raise StandardError.new(message) } rescue nil
        expect(controller).to have_received(:json_request_logger).with(foo: "bar", "error" => "foo", "bizz" => "buzz", start: "boo")
      end
    end
  end
end
