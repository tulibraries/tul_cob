# frozen_string_literal: true

require "rails_helper"

RSpec.describe TulConstraintComponent, type: :component do
  it "renders the legacy constraint layout with wrapped values" do
    presenter = instance_double(FacetItemPresenter,
                                field_label: "Facet",
                                constraint_label: "A Very Long Value",
                                remove_href: "/catalog")
    allow(presenter).to receive(:constraint_classes).and_return([])

    rendered = render_inline(described_class.new(facet_item_presenter: presenter)).to_html

    expect(rendered).to include("filterName")
    expect(rendered).to include("filterValue")
    expect(rendered).to include("A Very Long Value")
  end
end
