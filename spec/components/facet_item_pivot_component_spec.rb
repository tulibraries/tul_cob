# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacetItemPivotComponent, type: :component do

  let(:presenter) {
    presenter = instance_double(FacetItemPresenter)
    expect(presenter).to receive(:label).and_return "Foo"
    expect(presenter).to receive(:hits).and_return 10
    expect(presenter).to receive(:href).and_return "http://foo.bar/f"
    expect(presenter).to receive(:selected?).and_return false
    expect(presenter).to receive(:facet_item).and_return(OpenStruct.new(value: "foo"))
    allow(presenter).to receive(:facet_config).and_return(OpenStruct.new())
    allow(presenter).to receive(:items).and_return([])
    presenter
  }

  it "renders a spacer row for a parent facet" do
    expect(presenter).to receive(:has_selected_child?).and_return true
    allow(presenter).to receive(:nested?).and_return false
    render_inline FacetItemPivotComponent.new(
      facet_item: presenter,
      wrapping_element: nil,
      suppress_link: false)
    expect(rendered_component).to include "pivot-facet-spacer-row"
  end

  it "doesn't render a spacer row for a nested facet" do
    expect(presenter).to receive(:has_selected_child?).and_return false
    allow(presenter).to receive(:nested?).and_return true
    render_inline FacetItemPivotComponent.new(
      facet_item: presenter,
      wrapping_element: nil,
      suppress_link: false)
    expect(rendered_component).not_to include "pivot-facet-spacer-row"
  end
end
