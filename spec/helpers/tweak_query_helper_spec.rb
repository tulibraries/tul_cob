# frozen_string_literal: true

require "rails_helper"

RSpec.describe TweakQueryHelper, type: :helper do
  describe "#render_solr_search_tweaks"  do
    let(:solr_tweak_enable) { "on" }
    let(:config) { OpenStruct.new(default_solr_params: {}, document_model: SolrDocument) }
    let(:params) { {} }

    before(:each) {
      ENV["SOLR_SEARCH_TWEAK_ENABLE"] = solr_tweak_enable
      allow(helper).to receive(:render) {}
      allow(helper).to receive(:params) { params }
      allow(helper).to receive(:controller) { controller }

      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config) { config }
      end

      helper.render_solr_search_tweaks
    }

    after(:each) do
      ENV["SOLR_SEARCH_TWEAK_ENABLE"] = "off"
    end

    context "feature not enabled" do
      let(:solr_tweak_enable) { "off" }

      it "does not render" do
        expect(helper).to_not have_received(:render).with("tweak_solr_query_form")
      end
    end

    context "document model is not SolrDocument" do
      let(:config) { OpenStruct.new(document_model: Object) }

      it "does not render" do
        expect(helper).to_not have_received(:render).with("tweak_solr_query_form")
      end
    end

    context "feature is enabled" do
      it "should render the query tweak form" do
        expect(helper).to have_received(:render).with(partial: "tweak_solr_query_form", locals: { fields: {} })
      end

    end

    context "default solr params are provided" do
      let(:config) { OpenStruct.new(
        default_solr_params: { qf: "foo", title_pf: "bar", ignore_me: "WHA!" },
        document_model: SolrDocument
      )}

      it "filters out query and phrase fields" do
        expect(helper).to have_received(:render).with(partial: "tweak_solr_query_form", locals: { fields: { qf: "foo", title_pf: "bar" } })
      end
    end

    context "overrides are passed via params" do
      let(:config) { OpenStruct.new(
        default_solr_params: { qf: "foo", title_pf: "bar" },
        document_model: SolrDocument
      )}

      let (:params) { { qf: "buzz" } }

      it "overrides default params with passed in params" do
        expect(helper).to have_received(:render).with(partial: "tweak_solr_query_form", locals: { fields: { qf: "buzz", title_pf: "bar" } })
      end
    end
  end

  describe "#titleize_field" do
    it "transposes qf to Query Fields (qf)" do
      expect(helper.titleize_field "qf").to eq("Query Fields (qf)")
    end

    it "transposes pf to Phrase Fields (pf)" do
      expect(helper.titleize_field "pf").to eq("Phrase Fields (pf)")
    end

    it "titleizes" do
      expect(helper.titleize_field "hello_world").to eq("Hello World")
    end
  end
end
