# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClassificationFieldPresenter, type: :presenter do
  subject(:presenter) do
    described_class.new(facet_field, display_facet, view_context, search_state)
  end

  let(:facet_field) { Blacklight::Configuration::FacetField.new(key: "key") }
  let(:display_facet) do
    instance_double(Blacklight::Solr::Response::Facets::FacetField, items: items, sort: :index, offset: 0, prefix: nil)
  end
  let(:items) { [] }
  let(:controller) { c = CatalogController.new; c.params = {}; c }
  let(:view_context) { controller.view_context }
  let(:search_state) { view_context.search_state }

  before do
    allow(view_context).to receive(:facet_limit_for).and_return(20)
  end

  describe "#active?" do
    context "range lc_classification begin present" do
      it "is active" do
        controller.params[:range] = ActiveSupport::HashWithIndifferentAccess.new(lc_classification: { begin: "NB" })
        expect(presenter.active?).to eq(true)
      end
    end

    context "range lc_classification end present" do
      it "is active" do
        controller.params[:range] = ActiveSupport::HashWithIndifferentAccess.new(lc_classification: { end: "NB" })
        expect(presenter.active?).to eq(true)
      end
    end
  end

  describe "#collapsed?" do
    context "range lc_classification begin present" do
      it "is expanded" do
        controller.params[:range] = ActiveSupport::HashWithIndifferentAccess.new(lc_classification: { begin: "NB" })
        expect(presenter.collapsed?).to eq(false)
      end
    end

    context "range lc_classification end present" do
      it "is expanded" do
        controller.params[:range] = ActiveSupport::HashWithIndifferentAccess.new(lc_classification: { end: "NB" })
        expect(presenter.collapsed?).to eq(false)
      end
    end
  end
end
