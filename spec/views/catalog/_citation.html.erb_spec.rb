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
  let(:second_document) do
    SolrDocument.new(
      "id" => "456",
      "title_statement_display" => ["Second Book Title"],
      "creator_display" => ["Smith, John"],
      "pub_date_display" => ["2021"],
      "format" => ["Book"]
    )
  end
  before do
    allow(Flipflop).to receive(:citeproc_citations?).and_return(true)
    view.define_singleton_method(:blacklight_config) { CatalogController.blacklight_config }
    view.define_singleton_method(:has_search_parameters?) { false }
    presenter_class = Struct.new(:heading)
    view.define_singleton_method(:document_presenter) do |doc|
      presenter_class.new(doc["title_statement_display"].first)
    end
  end

  it "renders citeproc citations in the modal" do
    assign(:documents, [document])

    render partial: "catalog/citation"

    expect(rendered).to include("Example Book Title")
    expect(rendered).to include("citation_style_APA")
    expect(rendered).to include("Chicago Author-Date")
  end

  it "renders grouped citations for multiple documents" do
    assign(:documents, [document, second_document])

    render partial: "catalog/citation"

    expect(rendered).to include("By title")
    expect(rendered).to include("Example Book Title")
    expect(rendered).to include("Second Book Title")
  end
end
