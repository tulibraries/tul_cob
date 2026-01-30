# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/_citation.html.erb" do
  let(:document) do
    SolrDocument.new(
      "id" => "123",
      "title_statement_display" => ["Example Book Title"],
      "creator_display" => ["Doe, Jane"],
      "pub_date_display" => ["2020"],
      "format" => ["Book"]
    )
  end
  let(:response) { instance_double(Blacklight::Solr::Response, documents: [document]) }

  before do
    allow(Flipflop).to receive(:citeproc_citations?).and_return(true)
    view.define_singleton_method(:blacklight_config) { CatalogController.blacklight_config }
    view.define_singleton_method(:has_search_parameters?) { false }
    view.define_singleton_method(:document_heading) { |_doc| "Example Book Title" }
    assign(:response, response)
  end

  it "renders citeproc citations in the modal" do
    render partial: "catalog/citation"

    expect(rendered).to include("Example Book Title")
    expect(rendered).to include("citation_style_APA")
    expect(rendered).to include("Chicago Author-Date")
  end
end
