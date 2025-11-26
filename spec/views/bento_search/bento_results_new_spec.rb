# frozen_string_literal: true

require "rails_helper"

RSpec.describe "search/_bento_results_new.html.erb", type: :view do
  let(:result_item) do
    double(
      "result",
      failed?: false,
      engine_id: "archival_collections",
      total_items: { query_total: 1 }
    )
  end
  let(:results_hash) { { "archival_collections" => result_item } }
  let(:locals) do
    {
      results_class: "grid",
      results: results_hash,
      options: {}
    }
  end

  before do
    allow(view).to receive(:renderable_results).and_return(results_hash)
    allow(view).to receive(:with_libguides?).and_return(false)
    allow(view).to receive(:bento_grid_position_class).and_return("bento-grid-left")
    allow(view).to receive(:bento_search).and_return("archival-collections-card")
    allow(view).to receive(:render_linked_results_new).and_return("")
  end

  it "skips archival collections when flipflop is disabled" do
    allow(view).to receive(:aspace_integration_enabled?).and_return(false)

    render partial: "search/bento_results_new", locals: locals

    expect(rendered).not_to include("archival-collections-card")
  end

  it "renders archival collections when flipflop is enabled" do
    allow(view).to receive(:aspace_integration_enabled?).and_return(true)

    render partial: "search/bento_results_new", locals: locals

    expect(rendered).to include("archival-collections-card")
  end
end
