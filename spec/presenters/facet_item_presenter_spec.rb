# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacetItemPresenter, type: :presenter do
  subject(:presenter) do
    described_class.new(facet_item, facet_config, view_context, facet_field, search_state)
  end

  subject(:presenter_unselected) do
    described_class.new(Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo", hits: 100),
                        facet_config, view_context, facet_field, search_state)
  end

  let(:facet_item) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "cat", hits: 100, field: "pet") }
  let(:facet_config) { Blacklight::Configuration::FacetField.new(key: "pet") }
  let(:pivot_facet_config) { Blacklight::Configuration::FacetField.new(key: "pivot", pivot: ["job", "pet"]) }
  let(:facet_field) { instance_double(Blacklight::Solr::Response::Facets::FacetField) }
  let(:request) { ActionDispatch::TestRequest.create }
  let(:controller) { ViewComponent::Base.test_controller.constantize.new.tap { |c| c.request = request }.extend(Rails.application.routes.url_helpers) }
  let(:view_context) { controller.view_context }
  let(:search_state) { Blacklight::SearchState.new({ f: { pet: ["cat"], job: ["vet"], num: ["two"] } }, view_context.blacklight_config) }

  describe "has_selected_child?" do
    it "returns true if the presenter's facet_item contains a *single* sub item that is applied in the search state" do
      pet_facet_item_selected = Blacklight::Solr::Response::Facets::FacetItem.new(value: "cat", hits: 100, field: "pet")
      pet_facet_item_unselected = Blacklight::Solr::Response::Facets::FacetItem.new(value: "dog", hits: 100, field: "pet")
      parent_facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(value: "vet", hits: 100, items: [pet_facet_item_unselected])
      presenter = described_class.new(parent_facet_item, pivot_facet_config, view_context, facet_field, search_state)
      expect(presenter.has_selected_child?).to be false
      parent_facet_item.items = [pet_facet_item_selected]
      expect(presenter.has_selected_child?).to be true
    end
  end

  describe "href" do
    it "if parent and child are both selected, parent link keeps parent and drops child" do
      parent_facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(value: "vet", hits: 100, field: "job", items: [facet_item])
      presenter = described_class.new(parent_facet_item, pivot_facet_config, view_context, facet_field, search_state)
      expect(CGI.unescape(presenter.href)).to include "[job][]=vet"
      expect(CGI.unescape(presenter.href)).not_to include "[pet][]=cat"
    end

    it "if parent and child are both selected, child link drops both" do
      parent_facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(value: "vet", hits: 100, field: "job", items: [facet_item])
      presenter = described_class.new(facet_item, facet_config, view_context, facet_field, search_state)
      presenter.parent = parent_facet_item # this needs to be done in the pivot component
      expect(CGI.unescape(presenter.href)).not_to include "[job][]=vet"
      expect(CGI.unescape(presenter.href)).not_to include "[pet][]=cat"
    end

    it "doesn't tweak the actual search state when removing parts of href" do
      parent_facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(value: "vet", hits: 100, field: "job", items: [facet_item])
      presenter = described_class.new(parent_facet_item, pivot_facet_config, view_context, facet_field, search_state)
      presenter.href
      parent_facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(value: "vet", hits: 100, field: "job", items: [facet_item])
      presenter = described_class.new(facet_item, facet_config, view_context, facet_field, search_state)
      presenter.parent = parent_facet_item # this needs to be done in the pivot component
      presenter.href
      expect(search_state.filter_params.keys.sort).to eq %w(pet job num).sort
      expect(search_state.filter_params.values.flatten.sort).to eq %w(cat two vet)
    end
  end

  describe "items" do

    context "no sub items" do
      let(:item) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo", hits: 5, items: []) }

      it "doesn't alter the input" do
        presenter = described_class.new(item, facet_config, view_context, facet_field, search_state)
        presenter.items
        expected = Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo", hits: 5, items: [])
        expect(item).to eq(expected)
      end
    end

    context "sub items do not belong to the same library" do
      let(:sub_item_a) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo - bar", hits: 5, items: []) }
      let(:sub_item_b) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "booz - bar ", hits: 5, items: []) }
      let(:item) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo", hits: 5, items: [ sub_item_a, sub_item_b ]) }

      it "filters out items that do no match the library" do
        presenter = described_class.new(item, facet_config, view_context, "library_pivot_facet", search_state)
        expect(presenter.items).to eq([sub_item_a])
      end
    end

    context "sub item has 'foo - bar' value" do
      let(:sub_item_a) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo - bar", hits: 5, items: []) }
      let(:item) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo", hits: 5, items: [ sub_item_a ]) }

      it "transforms label to just be 'bar'" do
        presenter = described_class.new(item, facet_config, view_context, "library_pivot_facet", search_state)
        label = presenter.items.first.label
        expect(label).to eq("bar")
      end
    end

    context "sub item has 'foo - bar - buzz' value" do
      let(:sub_item_a) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo - bar - buzz", hits: 5, items: []) }
      let(:item) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "foo", hits: 5, items: [ sub_item_a ]) }

      it "transforms label to just be 'bar - buzz'" do
        presenter = described_class.new(item, facet_config, view_context, "library_pivot_facet", search_state)
        label = presenter.items.first.label
        expect(label).to eq("bar - buzz")
      end
    end
  end
end
