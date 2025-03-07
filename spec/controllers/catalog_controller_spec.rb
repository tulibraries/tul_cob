# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatalogController, type: :controller do

  let(:doc_id) { "991012041239703811" }
  let(:mock_response) { instance_double(Blacklight::Solr::Response) }
  let(:mock_document) { instance_double(SolrDocument) }
  let(:search_service) { instance_double(Blacklight::SearchService) }
  let(:doc) { Hash.new }
  let(:options) { { blacklight_config: controller.blacklight_config } }
  let(:document) { SolrDocument.new(doc, options) }

  describe "show action" do
    it "gets the staff_view_path" do
      get :show, params: { id: doc_id }
      expect(staff_view_path).to eq("/catalog/#{doc_id}/staff_view")
    end

    it "is properly routed for staff_view" do
      expect(get: "/catalog/:id/staff_view").to route_to(controller: "catalog", action: "librarian_view", id: ":id")
    end

    context "when the record is suppressed" do
      it "raises a record not found error if the record is suppressed", with_rescue: true do
        allow(search_service).to receive(:fetch).with(doc_id).and_raise(Blacklight::Exceptions::RecordNotFound)
        allow(controller).to receive(:search_service).and_return(search_service)

        get :show, params: { id: doc_id }
        expect(response).to render_template("errors/not_found")
      end
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
      %w[ creator_display imprint_display ]
    }

    context "an individual index result" do
      it "has an the expected fields" do
        expected_keys.each do |key|
          expect(docs_keys).to include key
        end
      end
    end
  end

  describe "using lower case boolean operators in normal search" do
    render_views
    it "returns more results that using uppercase boolean" do
      config = controller.blacklight_config
      (response_lower, _) = Blacklight::SearchService.new(config:, user_params: { q: "home or work" }).search_results
      (response_upper, _) = Blacklight::SearchService.new(config:, user_params: { q: "home OR work" }).search_results

      expect(response_upper.total).to be > response_lower.total
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

  describe "single_quoted_search vs non_single_quoted_search" do
    render_views
    let(:single_quoted_search_count) { JSON.parse(get(:index, params: { q: "'readers'" }, format: :json).body)["meta"]["pages"]["total_count"] }
    let(:non_single_quoted_search_count) { JSON.parse(get(:index, params: { q: "readers" }, format: :json).body)["meta"]["pages"]["total_count"] }

    it "should have a lower count for the single_quoted than the non_single_quoted search" do
      expect(single_quoted_search_count).to be < non_single_quoted_search_count
    end
  end

  describe "Boundwith Host records should not have been indexed" do
    render_views
    let(:bwh) { JSON.parse(get(:index, params: { q: "22293201420003811" }, format: :json).body)["meta"]["pages"]["total_count"] }

    it "returns no results" do
      expect(bwh).to eql 0
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

  describe "general param handling" do
    it "should remove duplicate facet param values" do
      expect(controller).to be_a_kind_of(ApplicationController)
      get :index , params: { f: { foo: [:bar, :bar] } }
      expect(controller.params["f"]["foo"].size).to eq(1)
    end
  end

  describe "advanced search" do
    it "doesn't error on empty search fields (example 1)" do
      expect {
        get :index, params: { search_field: "advanced", f_1: "all_fields", f_2: "all_fields", f_3: "all_fields",
                              op_1: "AND", operator: { q_1: "contains", q_2: "contains", q_3: "is" } }
        expect(response.code).to eq "200"
      }.to_not raise_error
    end

    it "doesn't error on empty search fields (example 2)" do
      expect {
        get :index, params: { search_field: "advanced", f_1: "all_fields", f_2: "creator_t", f_3: "all_fields",
                              op_1: "AND", op_2: "AND", operator: { q_1: "contains", q_2: "contains", q_3: "is" },
                              q_1: ". Research methods in psychology", q_2: "Morling", q_3: "" }
        expect(response.code).to eq "200"
      }.to_not raise_error
    end
  end

  describe "index page with no user params" do
    render_views

    it "does not send :search_results to the search_service" do
      allow(controller).to receive(:search_service).and_return(search_service)
      expect(search_service).to_not receive(:search_results)
      get :index
      expect(response).to render_template("catalog/_home")
      expect(response).not_to render_template("catalog/_search_results")
    end
  end

  describe "deciding to render or not to render lc classification fields on index" do
    render_views

    it "does not show the lc classification field by default" do
      get :index, params: { q: "art" }
      expect(response.body).not_to include "blacklight-lc_call_number_display"
    end

    it "shows the lc classification field when the lc range param is present" do
      get :index, params: { q: "art" , range: { lc_classification: { begin: "A", end: "Z" } } }
      expect(response.body).to include "blacklight-lc_call_number_display"
    end

    it "shows the lc classification field when the lc facet param is present" do
      get :index, params: { q: "art" , f: { lc_outer_facet: ["N - Fine Arts"] } }
      expect(response.body).to include "blacklight-lc_call_number_display"
    end

    it "shows the lc classification field when the lc sort param is present" do
      get :index, params: { q: "art" , sort: { lc_call_number_sort: true } }
      expect(response.body).to include "blacklight-lc_call_number_display"
    end
  end

  describe "before_action get_manifold_alerts" do
    context ":show action" do
      it "sets @manifold_alerts_thread" do
        get :show, params: { id: doc_id }
        expect(controller.instance_variable_get("@manifold_alerts_thread")).to be_kind_of(Thread)
      end
    end

    context ":index action" do
      it "sets @manifold_alerts_thread" do
        get :index, params: { q: "art" }
        expect(controller.instance_variable_get("@manifold_alerts_thread")).to be_kind_of(Thread)
      end
    end
  end

  describe "before_action override_solr_path " do
    context ":show action" do
      it "does not override the blacklight_config solr_path" do
        get :show, params: { id: doc_id }  rescue Blacklight::Exceptions::RecordNotFound

        expect(assigns(:blacklight_config).solr_path).to eq("search")
      end
    end

    context ":index action and quoted single term search (double quoted)" do
      it "overrides the blacklight_config solr_path" do
        get :index, params: { q: '"art"' }
        expect(assigns(:blacklight_config).solr_path).to eq("single_quoted_search")
      end
    end

    context ":index action and quoted single term search (single quoted)" do
      it "overrides the blacklight_config solr_path" do
        get :index, params: { q: "'art'" }
        expect(assigns(:blacklight_config).solr_path).to eq("single_quoted_search")
      end
    end

    context ":index action and non-quoted single term search" do
      it "overrides the blacklight_config solr_path" do
        get :index, params: { q: "art" }
        expect(assigns(:blacklight_config).solr_path).to eq("search")
      end
    end

    context ":index action and single term with apostrophe" do
      it "overrides the blacklight_config solr_path" do
        get :index, params: { q: "david's" }
        expect(assigns(:blacklight_config).solr_path).to eq("search")
      end
    end

    context ":index action and quoted multiple term search (single quoted)" do
      it "does not override the blacklight_config solr_path" do
        get :index, params: { q: "'art school'" }
        expect(assigns(:blacklight_config).solr_path).to eq("search")
      end
    end

    context ":index action and quoted multiple term search (double quoted)" do
      it "does not override the blacklight_config solr_path" do
        get :index, params: { q: "\"art school\"" }
        expect(assigns(:blacklight_config).solr_path).to eq("search")
      end
    end

    context ":index action and non-quoted multiple term search" do
      it "does not override the blacklight_config solr_path" do
        get :index, params: { q: "art school" }
        expect(assigns(:blacklight_config).solr_path).to eq("search")
      end
    end
  end
end
