# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrimoRangeFacetFieldPresenter, type: :presenter do
  let(:request) { ActionDispatch::TestRequest.create }
  let(:controller) { ApplicationController.new.tap { |c| c.request = request }.extend(Rails.application.routes.url_helpers) }
  let(:view_context) { controller.view_context }
  let(:facet_field) { Blacklight::Configuration::FacetField.new(key: "creationdate") }
  let(:search_state) { Blacklight::SearchState.new({}, view_context.blacklight_config) }
  let(:presenter) { described_class.new(facet_field, nil, view_context, search_state) }

  it "provides an empty display facet when no response is available" do
    expect(presenter.display_facet).to be_a(Blacklight::Solr::Response::Facets::NullFacetField)
  end
end
