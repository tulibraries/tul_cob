# frozen_string_literal: true

require "rails_helper"

RSpec.describe "bookmarks/_tools.html.erb" do
  let(:document) { double("SolrDocument", citable?: true) }
  let(:response) { instance_double(Blacklight::Solr::Response, documents: [document]) }
  let(:params_hash) { ActionController::Parameters.new(page: "2") }

  before do
    assign(:response, response)
    allow(Flipflop).to receive(:citeproc_citations?).and_return(false)
    view.define_singleton_method(:show_doc_actions?) { true }
    params_value = params_hash
    view.define_singleton_method(:params) { params_value }
    view.define_singleton_method(:csv_path) { "/bookmarks.csv" }
    view.define_singleton_method(:current_entries_info) { |_response| "1-10" }
    view.define_singleton_method(:render_results_collection_tools) { "" }
    allow(view).to receive(:render).and_call_original
    allow(view).to receive(:render)
      .with(instance_of(Bookmarks::SendToDropdownComponent))
      .and_return("")
  end

  it "does not render the cite button when citeproc is disabled" do
    render partial: "bookmarks/tools"

    expect(rendered).not_to include("citeLink")
  end
end
