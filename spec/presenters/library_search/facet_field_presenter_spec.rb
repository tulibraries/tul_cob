# frozen_string_literal: true

require "rails_helper"

RSpec.describe LibrarySearch::FacetFieldPresenter, type: :presenter do
  let(:request) { ActionDispatch::TestRequest.create }
  let(:controller) { ApplicationController.new.tap { |c| c.request = request }.extend(Rails.application.routes.url_helpers) }
  let(:view_context) { controller.view_context }
  let(:facet_field) do
    Blacklight::Configuration::FacetField.new(
      key: "library_facet",
      pivot: ["library_facet", "location_facet"],
      collapse: true
    )
  end
  let(:display_facet) { instance_double("Blacklight::Solr::Response::Facets::FacetField") }
  let(:search_state) do
    Blacklight::SearchState.new(
      { f: { location_facet: ["Ambler Campus Library - Stacks"] } },
      view_context.blacklight_config
    )
  end
  let(:presenter) { described_class.new(facet_field, display_facet, view_context, search_state) }

  it "keeps a pivot facet open when its child is selected" do
    expect(presenter).to be_active
    expect(presenter).not_to be_collapsed
  end

  it "sorts outer pivot values alphabetically" do
    items = [
      Blacklight::Solr::Response::Facets::FacetItem.new(value: "Ambler Campus Library", field: "library_facet", hits: 5),
      Blacklight::Solr::Response::Facets::FacetItem.new(value: "Charles Library", field: "library_facet", hits: 100),
      Blacklight::Solr::Response::Facets::FacetItem.new(value: "Blockson Collection", field: "library_facet", hits: 50)
    ]
    display_facet = Blacklight::Solr::Response::Facets::FacetField.new(
      "library_facet",
      items,
      limit: -1,
      sort: "index"
    )
    selected_search_state = Blacklight::SearchState.new(
      { f: { library_facet: ["Charles Library"] } },
      view_context.blacklight_config
    )
    selected_presenter = described_class.new(facet_field, display_facet, view_context, selected_search_state)

    expect(selected_presenter.paginator.items.map(&:value)).to eq([
      "Ambler Campus Library",
      "Blockson Collection",
      "Charles Library"
    ])
  end

end
