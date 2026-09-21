# frozen_string_literal: true

require "rails_helper"

RSpec.describe BlacklightConfigurationHelper, type: :helper do
  describe "#index_fields" do
    let(:default_fields) { [:default] }
    let(:document_fields) { [:document] }
    let(:default_config) { double(index_fields: default_fields) }
    let(:document_config) { double(index_fields: document_fields) }

    before do
      config = default_config
      helper.define_singleton_method(:blacklight_config) { config }
    end

    it "uses the document-specific configuration when present" do
      helper.instance_variable_set(:@blacklight_config, document_config)

      expect(helper.index_fields).to eq(document_fields)
    end

    it "falls back to the current configuration" do
      helper.instance_variable_set(:@blacklight_config, nil)

      expect(helper.index_fields).to eq(default_fields)
    end
  end

  describe "#facet_field_label" do
    let(:parent_field) do
      double(pivot: ["lc_facet", "lc_classification"])
    end
    let(:config) do
      double(facet_fields: { "lc_facet" => parent_field })
    end

    it "uses the parent facet label for the classification alias" do
      config = self.config
      helper.define_singleton_method(:blacklight_config) { config }
      allow(parent_field).to receive(:display_label)
        .with("facet")
        .and_return("Library of Congress Classification")

      expect(helper.facet_field_label("lc_classification")).to eq("Library of Congress Classification")
    end
  end
end
