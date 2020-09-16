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

  describe  "#render_facet_item" do
    context "field is library_pivot_facet" do
      it "calls #pre_preprocess_library_facet!" do
        allow(helper).to receive(:pre_process_library_facet!)
        helper.render_facet_item("library_pivot_facet", nil) rescue nil

        expect(helper).to have_received(:pre_process_library_facet!)
      end
    end
  end

  describe "#locations_map" do
    it "maps locations coldes to labels" do
      expect(locations_map["ASRS"]).to eq("BookBot")
    end
  end

  describe "#pre_process_library_facet!" do
    before do
      helper.pre_process_library_facet!(item)
    end

    context "no sub items" do
      let(:item) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo", hits: 5, items: []) }

      it "doesn't alter the input" do
        expected = Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo", hits: 5, items: [])
        expect(item).to eq(expected)
      end
    end

    context "sub items do not belong to the same library" do
      let(:sub_item_a) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo - bar", hits: 5, items: []) }
      let(:sub_item_b) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "booz - bar ", hits: 5, items: []) }
      let(:item) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo", hits: 5, items: [ sub_item_a, sub_item_b ]) }

      it "filters out items that do no match the library" do
        expect(item.items).to eq([sub_item_a])
      end
    end

    context "sub item cannot be translated" do
      let(:sub_item_a) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo - bar", hits: 5, items: []) }
      let(:item) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo", hits: 5, items: [ sub_item_a ]) }

      it "makes a label using sub item value but does not translate it" do
        label = item.items.first.label
        expect(label).to eq("bar")
      end
    end

    context "sub item can be translated" do
      let(:sub_item_a) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo - ASRS", hits: 5, items: []) }
      let(:item) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo", hits: 5, items: [ sub_item_a ]) }

      it "makes a label using sub item value and translates it" do
        label = item.items.first.label
        expect(label).to eq("BookBot")
      end
    end
  end

  describe "#with_library_locations_label" do
    let(:subject) { params.permit!; with_library_locations_labels(params) }

    before do
      params.permit!
    end

    context "no params" do
      let(:params) { ActionController::Parameters.new({}) }

      it "returns empty hash" do
        expect(subject).to eq({})
      end
    end

    context "params do not contain libray location facet" do
      let(:params) { ActionController::Parameters.new({ f: { foo: [] } }) }

      it "returns the params" do
        expect(subject).to eq(params)
      end
    end

    context "it does contatin library location facet" do
      let(:params) { ActionController::Parameters.new({ f: { location_facet: [ "foo - ASRS"] } }) }

      it "maps the location facet to the location label" do
        expect(subject).to eq(ActionController::Parameters.new({ f: { location_facet: ["foo - BookBot"], library_facet: [] }.with_indifferent_access }))
      end
    end

    context "it does contatin library location facet and matching library foo" do
      let(:params) { ActionController::Parameters.new({ f: { location_facet: [ "foo - ASRS"], library_facet: [ "foo" ] } }) }

      it "removes the matching library from the facet" do
        expect(subject).to eq(ActionController::Parameters.new({ f: { location_facet: ["foo - BookBot"], library_facet: [] }.with_indifferent_access }))
      end
    end

    context "it does contatin library location facet and non matching library bar" do
      let(:params) { ActionController::Parameters.new({ f: { location_facet: [ "foo - ASRS"], library_facet: [ "bar" ] } }) }

      it "keeps the non mathingn library facet" do
        expect(subject).to eq(ActionController::Parameters.new({ f: { location_facet: ["foo - BookBot"], library_facet: [ "bar" ] }.with_indifferent_access }))
      end
    end
  end
end
