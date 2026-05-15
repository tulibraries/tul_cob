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
end
