# frozen_string_literal: true

require "rails_helper"

RSpec.describe LibrarySearch::FacetItemComponent, type: :component do

  def render_component(presenter)
    render_inline described_class.new(
      facet_item: presenter,
      wrapping_element: nil,
      suppress_link: false)
  end

  let(:presenter) {
    presenter = instance_double(PivotFacetItemPresenter)
    allow(presenter).to receive(:label).and_return "Foo"
    allow(presenter).to receive(:hits).and_return 10
    allow(presenter).to receive(:href).and_return "http://foo.bar/f"
    allow(presenter).to receive(:selected?).and_return false
    allow(presenter).to receive(:facet_field).and_return facet_field
    allow(presenter).to receive(:facet_item).and_return(OpenStruct.new(value: "foo"))
    presenter
  }

  let(:facet_field) { "format" }

  it "renders the facet" do
    render_component presenter
    expect(rendered_content).to include "facet_foo"
    expect(rendered_content).to include ">Foo<"
    expect(rendered_content).to include "foo.bar"
    expect(rendered_content).to include "10"
  end

  context "when rendering a pivot facet" do
    let(:facet_field) { "library_facet" }

    it "does not add a resource type icon class to the facet value" do
      allow(presenter).to receive(:label).and_return "Media"

      render_component presenter

      expect(rendered_content).to include 'class="facet-select"'
      expect(rendered_content).not_to include "facet_media"
    end
  end

  context "when rendering a database resource type facet" do
    let(:facet_field) { "az_format" }

    it "adds a resource type icon class to the facet value" do
      allow(presenter).to receive(:label).and_return "Newspapers"
      allow(presenter).to receive(:facet_item).and_return(OpenStruct.new(value: "newspapers"))

      render_component presenter

      expect(rendered_content).to include "facet_newspapers"
    end
  end

  context "when rendering an article resource type facet" do
    let(:facet_field) { "rtype" }

    it "adds a resource type icon class to the facet value" do
      allow(presenter).to receive(:label).and_return "Journal Article"
      allow(presenter).to receive(:facet_item).and_return(OpenStruct.new(value: "articles"))

      render_component presenter

      expect(rendered_content).to include "facet_articles"
      expect(rendered_content).not_to include "facet_journal_article"
    end
  end
end
