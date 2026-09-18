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
end
