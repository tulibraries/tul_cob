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

  describe "#collapsed?" do
    it "is collapsed by default" do
      facet_field.collapse = true
      expect(presenter.collapsed?).to be true
    end

    it "does not be collapse if the configuration says so" do
      facet_field.collapse = false
      expect(presenter.collapsed?).to eq(false)
    end

    it "does not be collapsed if it is in the params" do
      controller.params[:f] = ActiveSupport::HashWithIndifferentAccess.new(key: [1])
      expect(presenter.collapsed?).to be false
    end

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

  describe "#active?" do
    it "checks if any value is selected for a given facet" do
      controller.params[:f] = ActiveSupport::HashWithIndifferentAccess.new(key: [1])
      expect(presenter.active?).to eq true
    end

    it "is false if no value for facet is selected" do
      expect(presenter.active?).to eq false
    end
  end
end
