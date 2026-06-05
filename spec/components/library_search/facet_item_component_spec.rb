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
    allow(presenter).to receive(:facet_item).and_return(OpenStruct.new(value: "foo"))
    presenter
  }

  it "renders the facet" do
    render_component presenter
    expect(rendered_content).to include "facet_foo"
    expect(rendered_content).to include ">Foo<"
    expect(rendered_content).to include "foo.bar"
    expect(rendered_content).to include "10"
  end
end
