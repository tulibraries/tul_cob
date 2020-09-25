# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacetsHelper, type: :helper do
  describe "#render_facet_limit" do
    let(:component_class) do
      Class.new(Blacklight::FacetFieldListComponent) do
        def render_in(*args)
          "Here I am"
        end

        def self.name
          "Dummy Component Class"
        end
      end
    end
    let(:config) do
      Blacklight::Configuration.new do |config|
        config.add_facet_field "foo", show: true, component: component_class
        config.add_facet_field "bar", show: false, component: component_class
      end
    end
    let(:params) { ActionController::Parameters.new q: "biz" }
    let(:path) { Blacklight::SearchState.new(params, config, controller) }

    before do
      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config).and_return(config)
        allow(helper).to receive(:blacklight_configuration_context).and_return(Blacklight::Configuration::Context.new(self))
        allow(helper).to receive(:search_state).and_return(Blacklight::SearchState.new({}, config, helper))
        allow(helper).to receive(:search_action_path)
        allow(helper).to receive(:facet_limit_for).and_return(1)
      end
    end

    it "won't render a component when the config says not to" do
      dblFoo = double("Foo", name: "foo", items: [Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo", hits: 5)], sort: "count", offset: 0, prefix: nil)
      dblBar = double("Bar", name: "bar", items: [Blacklight::Solr::Response::Facets::FacetItem.new(value: "bar", hits: 5)], sort: "count", offset: 0, prefix: nil)

      expect(helper.render_facet_limit(dblFoo)).to eql "Here I am"
      expect(helper.render_facet_limit(dblBar)).to be_nil

    end
  end
end
