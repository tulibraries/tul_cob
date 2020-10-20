# frozen_string_literal: true

require "rails_helper"

RSpec.describe FacetItemComponent, type: :component do

  def render_component(presenter)
    render_inline FacetItemComponent.new(
      facet_item: presenter,
      wrapping_element: nil,
      suppress_link: false)
  end

  let(:presenter) {
    presenter = instance_double(FacetItemPresenter)
    expect(presenter).to receive(:label).and_return "Foo"
    expect(presenter).to receive(:hits).and_return 10
    expect(presenter).to receive(:href).and_return "http://foo.bar/f"
    expect(presenter).to receive(:selected?).and_return false
    expect(presenter).to receive(:facet_item).and_return(OpenStruct.new(value: "foo"))
    presenter
  }

  it "renders the facet" do
    expect(presenter).to receive(:has_selected_child?).and_return false
    result = render_component presenter
    expect(rendered_component).to include "facet_foo"
    expect(rendered_component).to include ">Foo<"
    expect(rendered_component).to include "foo.bar"
    expect(rendered_component).to include "10"
  end

  it "doesn't render a count if the facet has a selected child" do
    expect(presenter).to receive(:has_selected_child?).and_return true
    result = render_component presenter
    expect(rendered_component).not_to include "10"
  end
end
