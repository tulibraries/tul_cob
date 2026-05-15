# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacetItemPivotComponent, type: :component do

  let(:presenter) {
    presenter = instance_double(PivotFacetItemPresenter)
    search_state = double("search_state")
    allow(search_state).to receive(:filter).and_return([])
    allow(presenter).to receive(:label).and_return "Foo"
    allow(presenter).to receive(:hits).and_return 10
    allow(presenter).to receive(:href).and_return "http://foo.bar/f"
    allow(presenter).to receive(:selected?).and_return false
    allow(presenter).to receive(:facet_item).and_return(OpenStruct.new(value: "foo"))
    allow(presenter).to receive(:facet_config).and_return(OpenStruct.new(collapsing: true, icons: {}))
    allow(presenter).to receive(:items).and_return([])
    allow(presenter).to receive(:facet_item_presenters).and_return([])
    allow(presenter).to receive(:search_state).and_return(search_state)
    presenter
  }

  it "renders a spacer row for a parent facet" do
    allow(presenter).to receive(:has_selected_child?).and_return true
    allow(presenter).to receive(:nested?).and_return false
    component = FacetItemPivotComponent.new(
      facet_item: presenter,
      wrapping_element: nil,
      suppress_link: false)
    allow(component).to receive(:has_items?).and_return(true)
    render_inline component
    expect(rendered_content).to include "pivot-facet-spacer-row"
    expect(rendered_content).to include 'data-bs-target="'
    expect(rendered_content).to include 'type="button"'
    expect(rendered_content).to include 'class="show"'
    expect(rendered_content).to include 'class="hide"'
  end

  it "doesn't render a spacer row for a nested facet" do
    allow(presenter).to receive(:has_selected_child?).and_return false
    allow(presenter).to receive(:nested?).and_return true
    render_inline FacetItemPivotComponent.new(
      facet_item: presenter,
      wrapping_element: nil,
      suppress_link: false)
    expect(rendered_content).not_to include "pivot-facet-spacer-row"
  end
end
