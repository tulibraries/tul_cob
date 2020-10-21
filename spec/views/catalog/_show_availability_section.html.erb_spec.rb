# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/_show_availability_section.html.erb", type: :view do

  include BlacklightHelper
  include CatalogHelper

  let(:user_signed_in?) { false }
  let(:config) { Blacklight::Configuration.new }

  before(:each) do
    config.show.document_presenter_class = ShowPresenter

    allow(view).to receive(:user_signed_in?) { user_signed_in? }
    allow(view).to receive(:item_url).and_return "https://example.com/foo"

    without_partial_double_verification do
      allow(view).to receive(:blacklight_config).and_return config
    end
  end

  context "viewing a SolrDocument" do
    let (:document) { SolrDocument.new(id: "foo") }

    it "adds stimulus show controller stuff" do
      render "catalog/show_availability_section", document: document
      expect(rendered).to match(/<div data-controller="show"/)
    end
  end

  context "viewing a SolrDatabaseDocument" do
    let(:document) { SolrDatabaseDocument.new(id: 1) }

    it "does not add stimulus show controller stuff" do
      render "catalog/show_availability_section", document: document
      expect(rendered).not_to match(/<div data-controller="show"/)
    end
  end
end
