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


  let(:facet_item) { Blacklight::Solr::Response::Facets::FacetItem.new(value: "cat", hits: 100) }
  let(:facet_config) { Blacklight::Configuration::FacetField.new(key: "pet") }
  let(:facet_field) { instance_double(Blacklight::Solr::Response::Facets::FacetField) }
  let(:request) { ActionDispatch::TestRequest.create }
  let(:controller) { ViewComponent::Base.test_controller.constantize.new.tap { |c| c.request = request }.extend(Rails.application.routes.url_helpers) }
  let(:view_context) { controller.view_context }
  let(:search_state) { Blacklight::SearchState.new({ f: { pet: ["cat"], job: ["vet"], num: ["two"] } }, view_context.blacklight_config) }

  describe "keep_in_params!" do
    it "lets a selected facet keep itself in the href it generates" do
        expect(presenter.selected?).to be true
        expect(CGI.unescape(presenter.href)).not_to include "[pet][]=cat"
        expect(CGI.unescape(presenter.href)).to include "[job][]=vet"

        presenter.keep_in_params!
        expect(CGI.unescape(presenter.href)).to include "[pet][]=cat"
        expect(CGI.unescape(presenter.href)).to include "[job][]=vet"
      end
  end

  describe "hide_facet_param" do
    it "allows other facets to be arbitrarily hidden when rendering the href" do
      expect(CGI.unescape(presenter.href)).to include "[job][]=vet"
      hide_me = Blacklight::Solr::Response::Facets::FacetItem.new(value: "vet", hits: 100, field: "job")
      presenter.hide_facet_param(hide_me)
      expect(CGI.unescape(presenter.href)).not_to include "[job][]=vet"

      expect(CGI.unescape(presenter_unselected.href)).to include "[job][]=vet"
      presenter_unselected.hide_facet_param(hide_me)
      expect(CGI.unescape(presenter_unselected.href)).not_to include "[job][]=vet"
    end

    it "works with keep in params" do
      presenter.keep_in_params!
      hide_me = Blacklight::Solr::Response::Facets::FacetItem.new(value: "vet", hits: 100, field: "job")
      presenter.hide_facet_param(hide_me)
      expect(CGI.unescape(presenter.href)).to include "[pet][]=cat"
      expect(CGI.unescape(presenter.href)).not_to include "[job][]=vet"
    end

    it "doesn't tweak the actual search state" do
      hide_me = Blacklight::Solr::Response::Facets::FacetItem.new(value: "vet", hits: 100, field: "job")
      expect(search_state[:f].keys.sort).to eq %w(pet job num).sort
      presenter.hide_facet_param(hide_me)
      presenter.href
      expect(search_state[:f].keys.sort).to eq %w(pet job num).sort
      presenter.keep_in_params!
      presenter.href
      expect(search_state[:f].keys.sort).to eq %w(pet job num).sort
    end
  end
end
