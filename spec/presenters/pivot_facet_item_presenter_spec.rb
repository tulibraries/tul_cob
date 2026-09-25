# frozen_string_literal: true

require "rails_helper"

RSpec.describe PivotFacetItemPresenter, type: :presenter do
  let(:request) { ActionDispatch::TestRequest.create }
  let(:controller) { ApplicationController.new.tap { |c| c.request = request }.extend(Rails.application.routes.url_helpers) }
  let(:view_context) { controller.view_context }
  let(:facet_field) { "library_facet" }
  let(:facet_config) { Blacklight::Configuration::FacetField.new(key: "library_facet", pivot: ["library_facet", "location_facet"]) }
  let(:search_state) { Blacklight::SearchState.new({}, view_context.blacklight_config) }

  it "shows only the location label for nested library pivot values" do
    facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(
      value: "Ambler Campus Library - Stacks",
      label: "Ambler Campus Library - Stacks",
      hits: 5,
      field: "location_facet"
    )
    presenter = described_class.new(facet_item, facet_config, view_context, facet_field, search_state)
    presenter.parent = Blacklight::Solr::Response::Facets::FacetItem.new(value: "Ambler Campus Library", field: "library_facet")

    expect(presenter.label).to eq("Stacks")
  end

  it "marks a selected library parent as selected" do
    search_state = Blacklight::SearchState.new(
      { f: { library_facet: ["Ambler Campus Library"] } },
      view_context.blacklight_config
    )
    facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(
      value: "Ambler Campus Library",
      hits: 5,
      field: "library_facet"
    )
    presenter = described_class.new(facet_item, facet_config, view_context, facet_field, search_state)

    expect(presenter.selected?).to be true
  end

  it "removes the library parent when adding a nested location" do
    search_state = Blacklight::SearchState.new(
      { f: { library_facet: ["Ambler Campus Library"] } },
      view_context.blacklight_config
    )
    facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(
      value: "Ambler Campus Library - Stacks",
      hits: 5,
      field: "location_facet",
      fq: { library_facet: "Ambler Campus Library" }
    )
    presenter = described_class.new(facet_item, facet_config, view_context, facet_field, search_state)
    presenter.parent = Blacklight::Solr::Response::Facets::FacetItem.new(
      value: "Ambler Campus Library",
      field: "library_facet"
    )

    href = CGI.unescape(presenter.href)

    expect(href).to include("[location_facet][]=Ambler Campus Library - Stacks")
    expect(href).not_to include("[library_facet]")
  end

  it "puts selected nested locations first and then sorts by count" do
    search_state = Blacklight::SearchState.new(
      { f: { location_facet: ["Ambler Campus Library - Stacks"] } },
      view_context.blacklight_config
    )
    facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(
      value: "Ambler Campus Library",
      field: "library_facet",
      items: [
        Blacklight::Solr::Response::Facets::FacetItem.new(value: "Ambler Campus Library - Archives", field: "location_facet", hits: 8),
        Blacklight::Solr::Response::Facets::FacetItem.new(value: "Ambler Campus Library - Stacks", field: "location_facet", hits: 1),
        Blacklight::Solr::Response::Facets::FacetItem.new(value: "Ambler Campus Library - IMC", field: "location_facet", hits: 4)
      ]
    )
    presenter = described_class.new(facet_item, facet_config, view_context, facet_field, search_state)

    expect(presenter.items.map(&:value)).to eq([
      "Ambler Campus Library - Stacks",
      "Ambler Campus Library - Archives",
      "Ambler Campus Library - IMC"
    ])
  end

  it "sorts Library of Congress inner values alphabetically" do
    facet_config = Blacklight::Configuration::FacetField.new(
      key: "lc_facet",
      pivot: ["lc_outer_facet", "lc_inner_facet"]
    )
    facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(
      value: "M - Music",
      field: "lc_outer_facet",
      items: [
        Blacklight::Solr::Response::Facets::FacetItem.new(value: "ML - Literature on Music", field: "lc_inner_facet", hits: 8),
        Blacklight::Solr::Response::Facets::FacetItem.new(value: "M - Music", field: "lc_inner_facet", hits: 1),
        Blacklight::Solr::Response::Facets::FacetItem.new(value: "MT - Musical Instruction & Study", field: "lc_inner_facet", hits: 100)
      ]
    )
    presenter = described_class.new(facet_item, facet_config, view_context, "lc_facet", search_state)

    expect(presenter.items.map(&:value)).to eq([
      "M - Music",
      "ML - Literature on Music",
      "MT - Musical Instruction & Study"
    ])
  end

  it "uses the default label for a non-library pivot item" do
    facet_config = Blacklight::Configuration::FacetField.new(
      key: "lc_facet",
      pivot: ["lc_outer_facet", "lc_inner_facet"]
    )
    facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(
      value: "ML - Literature on Music",
      field: "lc_inner_facet",
      fq: { lc_outer_facet: "M - Music" }
    )
    presenter = described_class.new(facet_item, facet_config, view_context, "lc_facet", search_state)

    expect(presenter.label).to eq("ML - Literature on Music")
  end

  it "filters unrelated library locations and shortens matching labels" do
    facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(
      value: "Ambler Campus Library",
      field: "library_facet",
      items: [
        Blacklight::Solr::Response::Facets::FacetItem.new(value: "Ambler Campus Library - Stacks", hits: 5),
        Blacklight::Solr::Response::Facets::FacetItem.new(value: "Other Library - Stacks", hits: 10),
        Blacklight::Solr::Response::Facets::FacetItem.new(value: "Ambler Campus Library", hits: 1)
      ]
    )
    presenter = described_class.new(facet_item, facet_config, view_context, facet_field, search_state)

    expect(presenter.items.map(&:value)).to eq([
      "Ambler Campus Library - Stacks",
      "Ambler Campus Library"
    ])
    expect(presenter.items.map(&:label)).to eq(["Stacks", "Ambler Campus Library"])
  end

  it "returns an empty list when the facet has no items" do
    presenter = described_class.new("Library", facet_config, view_context, facet_field, search_state)

    expect(presenter.items).to eq([])
  end

  it "checks the selected value for a nested item" do
    search_state = Blacklight::SearchState.new(
      { f: { location_facet: ["Ambler Campus Library - Stacks"] } },
      view_context.blacklight_config
    )
    facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(
      value: "Ambler Campus Library - Stacks",
      field: "location_facet"
    )
    presenter = described_class.new(facet_item, facet_config, view_context, facet_field, search_state)

    expect(presenter.selected?).to be true
  end

  it "returns false for an unselected non-pivot item" do
    facet_config = Blacklight::Configuration::FacetField.new(key: "format")
    facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(value: "Book", field: "format")
    presenter = described_class.new(facet_item, facet_config, view_context, "format", search_state)

    expect(presenter.selected?).to be false
  end

  it "uses remove_href for a selected item" do
    presenter = described_class.new(
      Blacklight::Solr::Response::Facets::FacetItem.new(value: "Library", field: "library_facet"),
      facet_config,
      view_context,
      facet_field,
      search_state
    )
    allow(presenter).to receive(:selected?).and_return(true)
    allow(presenter).to receive(:remove_href).and_return("/remove")

    expect(presenter.href).to eq("/remove")
  end

  it "uses add_href for an unselected nested item" do
    presenter = described_class.new(
      Blacklight::Solr::Response::Facets::FacetItem.new(value: "Library - Stacks", field: "location_facet"),
      facet_config,
      view_context,
      facet_field,
      search_state
    )
    allow(presenter).to receive(:selected?).and_return(false)
    allow(presenter).to receive(:add_href).and_return("/add")

    expect(presenter.href).to eq("/add")
  end

  it "uses the inherited href behavior for an unselected non-pivot item" do
    facet_config = Blacklight::Configuration::FacetField.new(key: "format")
    presenter = described_class.new(
      Blacklight::Solr::Response::Facets::FacetItem.new(value: "Book", field: "format"),
      facet_config,
      view_context,
      "format",
      search_state
    )
    allow(view_context).to receive(:search_action_path).and_return("/search")

    expect(presenter.href).to eq("/search")
    expect(view_context).to have_received(:search_action_path)
  end

  it "removes a selected parent facet from the search path" do
    search_state = Blacklight::SearchState.new(
      { f: { library_facet: ["Ambler Campus Library"] } },
      view_context.blacklight_config
    )
    facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(
      value: "Ambler Campus Library",
      field: "library_facet"
    )
    presenter = described_class.new(facet_item, facet_config, view_context, facet_field, search_state)
    allow(view_context).to receive(:search_action_path).and_return("/search")

    expect(presenter.href).to eq("/search")
    expect(view_context).to have_received(:search_action_path)
  end

  it "reports when a library parent has a selected child" do
    search_state = Blacklight::SearchState.new(
      { f: { location_facet: ["Ambler Campus Library - Stacks"] } },
      view_context.blacklight_config
    )
    facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(
      value: "Ambler Campus Library",
      field: "library_facet",
      items: [
        Blacklight::Solr::Response::Facets::FacetItem.new(
          value: "Ambler Campus Library - Stacks",
          field: "location_facet",
        )
      ]
    )
    presenter = described_class.new(facet_item, facet_config, view_context, facet_field, search_state)

    expect(presenter.has_selected_child?).to be true
  end

  it "returns false when a facet item cannot have selected children" do
    string_presenter = described_class.new("Library", facet_config, view_context, facet_field, search_state)
    parent_presenter = described_class.new(
      Blacklight::Solr::Response::Facets::FacetItem.new(value: "Library", field: "library_facet"),
      facet_config,
      view_context,
      facet_field,
      search_state
    )
    parent_presenter.parent = Blacklight::Solr::Response::Facets::FacetItem.new(value: "Parent", field: "library_facet")
    non_pivot_config = Blacklight::Configuration::FacetField.new(key: "format")
    non_pivot_presenter = described_class.new(
      Blacklight::Solr::Response::Facets::FacetItem.new(value: "Book", field: "format"),
      non_pivot_config,
      view_context,
      "format",
      search_state
    )

    expect(string_presenter.has_selected_child?).to be false
    expect(parent_presenter.has_selected_child?).to be false
    expect(non_pivot_presenter.has_selected_child?).to be false
  end

  it "removes a selected child facet while preserving the parent filter" do
    child_value = "Ambler Campus Library - Stacks"
    search_state = Blacklight::SearchState.new(
      { f: { library_facet: ["Ambler Campus Library"], location_facet: [child_value] } },
      view_context.blacklight_config
    )
    facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(
      value: "Ambler Campus Library",
      field: "library_facet",
      items: [Blacklight::Solr::Response::Facets::FacetItem.new(value: child_value, field: "location_facet")]
    )
    presenter = described_class.new(facet_item, facet_config, view_context, facet_field, search_state)
    allow(view_context).to receive(:search_action_path).and_return("/search")

    expect(presenter.remove_href).to eq("/search")
    expect(view_context).to have_received(:search_action_path).with(
      hash_including(f: hash_not_including(:location_facet))
    )
  end

  it "removes a selected nested child and its selected parent" do
    child_value = "Ambler Campus Library - Stacks"
    search_state = Blacklight::SearchState.new(
      { f: { library_facet: ["Ambler Campus Library"], location_facet: [child_value] } },
      view_context.blacklight_config
    )
    parent = Blacklight::Solr::Response::Facets::FacetItem.new(value: "Ambler Campus Library", field: "library_facet")
    child = Blacklight::Solr::Response::Facets::FacetItem.new(value: child_value, field: "location_facet")
    presenter = described_class.new(child, facet_config, view_context, facet_field, search_state)
    presenter.parent = parent
    allow(view_context).to receive(:search_action_path).and_return("/search")

    expect(presenter.href).to eq("/search")
    expect(view_context).to have_received(:search_action_path).with(hash_not_including(:f))
  end

  it "returns the parent facet value from a symbol keyed filter query" do
    facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(
      value: "Ambler Campus Library - Stacks",
      field: "location_facet",
      fq: { library_facet: "Ambler Campus Library" }
    )
    presenter = described_class.new(facet_item, facet_config, view_context, facet_field, search_state)

    expect(presenter.parent_facet_value).to eq("Ambler Campus Library")
  end

  it "returns the assigned parent facet value" do
    parent = Blacklight::Solr::Response::Facets::FacetItem.new(value: "Ambler Campus Library", field: "library_facet")
    presenter = described_class.new(
      Blacklight::Solr::Response::Facets::FacetItem.new(value: "Stacks", field: "location_facet"),
      facet_config,
      view_context,
      facet_field,
      search_state
    )
    presenter.parent = parent

    expect(presenter.parent_facet_value).to eq("Ambler Campus Library")
  end

  it "returns nil when a facet item has no parent filter" do
    presenter = described_class.new("Stacks", facet_config, view_context, facet_field, search_state)

    expect(presenter.parent_facet_value).to be_nil
  end

  it "returns the parent facet value from a string keyed filter query" do
    facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(
      value: "Ambler Campus Library - Stacks",
      field: "location_facet",
      fq: { "library_facet" => "Ambler Campus Library" }
    )
    presenter = described_class.new(facet_item, facet_config, view_context, facet_field, search_state)

    expect(presenter.parent_facet_value).to eq("Ambler Campus Library")
  end

  it "recognizes a pivot item as nested when its field is the inner pivot field" do
    facet_item = Blacklight::Solr::Response::Facets::FacetItem.new(
      value: "M - Music",
      field: "lc_inner_facet"
    )
    facet_config = Blacklight::Configuration::FacetField.new(
      key: "lc_facet",
      pivot: ["lc_outer_facet", "lc_inner_facet"]
    )
    presenter = described_class.new(facet_item, facet_config, view_context, "lc_facet", search_state)

    expect(presenter.nested?).to be true
  end

  it "checks string-keyed facet parameters" do
    state = instance_double(Blacklight::SearchState, params: { "f" => { "format" => ["Book"] } })
    facet_config = Blacklight::Configuration::FacetField.new(key: "format")
    presenter = described_class.new(
      Blacklight::Solr::Response::Facets::FacetItem.new(value: "Book", field: "format"),
      facet_config,
      view_context,
      "format",
      state
    )

    expect(presenter.selected_facet_value?("format", "Book")).to be true
  end

  it "supports overriding the constraint label and adding constraint classes" do
    presenter = described_class.new(
      Blacklight::Solr::Response::Facets::FacetItem.new(value: "Library", field: "library_facet"),
      facet_config,
      view_context,
      facet_field,
      search_state
    )
    presenter.constraint_label_override = "Libraries"
    presenter.add_constraint_class("highlight")
    presenter.add_constraint_class(nil)

    expect(presenter.constraint_label).to eq("Libraries")
    expect(presenter.constraint_classes).to eq(["highlight"])
  end

  it "creates a child presenter with the current item as its parent" do
    parent = Blacklight::Solr::Response::Facets::FacetItem.new(value: "Ambler Campus Library", field: "library_facet")
    child = Blacklight::Solr::Response::Facets::FacetItem.new(value: "Ambler Campus Library - Stacks", field: "location_facet")
    presenter = described_class.new(parent, facet_config, view_context, facet_field, search_state)

    child_presenter = presenter.facet_item_presenter(child)

    expect(child_presenter).to be_a(described_class)
    expect(child_presenter.facet_item).to eq(child)
    expect(child_presenter.nested?).to be true
  end
end
