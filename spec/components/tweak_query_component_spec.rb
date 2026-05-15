# frozen_string_literal: true

require "rails_helper"

RSpec.describe TweakQueryComponent, type: :component do
  let(:default_solr_params) { { "qf" => "foo", "title_pf" => "bar", "ignore_me" => "noop" } }
  let(:blacklight_config) { OpenStruct.new(default_solr_params:, document_model:) }
  let(:document_model) { SolrDocument }
  let(:params_hash) { {} }
  let(:params) { ActionController::Parameters.new(params_hash) }

  before do
    allow(Flipflop).to receive(:solr_query_tweaks?).and_return(feature_enabled)
  end

  context "when the feature flag is disabled" do
    let(:feature_enabled) { false }

    it "renders nothing" do
      result = render_inline(described_class.new(blacklight_config:, params:))
      expect(result.to_html).to be_blank
    end
  end

  context "when the document model is not SolrDocument" do
    let(:feature_enabled) { true }
    let(:document_model) { Object }

    it "renders nothing" do
      result = render_inline(described_class.new(blacklight_config:, params:))
      expect(result.to_html).to be_blank
    end
  end

  context "when enabled" do
    let(:feature_enabled) { true }

    it "renders the tweak controls" do
      result = render_inline(described_class.new(blacklight_config:, params:))
      expect(result.css("textarea[name='qf']").text).to eq("foo")
      expect(result.css("textarea[name='title_pf']").text).to eq("bar")
      expect(result.to_html).not_to include("ignore_me")
    end

    context "with overriding params" do
      let(:params_hash) { { qf: "buzz" } }

      it "prefers the param supplied values" do
        result = render_inline(described_class.new(blacklight_config:, params:))
        expect(result.css("textarea[name='qf']").text).to eq("buzz")
      end
    end
  end
end
