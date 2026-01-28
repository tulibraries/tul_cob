# frozen_string_literal: true

require "rails_helper"
require "csv"

RSpec.describe CsvExportable, type: :model do
  let(:document) do
    SolrDocument.new(
      "title_statement_display" => ["The Title"],
      "creator_display" => ["Author One", "Author Two"],
      "call_number_display" => ["ABC 123"]
    )
  end

  it "registers CSV as an export format" do
    expect(document.export_formats).to have_key(:csv)
  end

  it "exports a single CSV row with joined values" do
    row = CSV.parse_line(document.export_as_csv)
    expect(row).to eq(["The Title", "Author One; Author Two", "ABC 123"])
  end

  it "prefers the title-with-subtitle field when present" do
    titled_document = SolrDocument.new(
      "title_with_subtitle_display" => ["Main title : subtitle"],
      "title_statement_display" => ["Main title / Author"],
      "creator_display" => ["Author One"],
      "call_number_display" => ["ABC 123"]
    )

    row = CSV.parse_line(titled_document.export_as_csv)
    expect(row[0]).to eq("Main title : subtitle")
  end

  it "prefers the truncated title-with-subtitle field when full is missing" do
    titled_document = SolrDocument.new(
      "title_with_subtitle_truncated_display" => ["Main title : subtitle"],
      "title_statement_display" => ["Main title / Author"],
      "creator_display" => ["Author One"],
      "call_number_display" => ["ABC 123"]
    )

    row = CSV.parse_line(titled_document.export_as_csv)
    expect(row[0]).to eq("Main title : subtitle")
    expect(row[0]).not_to include("Author")
  end

  it "returns blank fields when values are missing" do
    empty_document = SolrDocument.new({})
    row = CSV.parse_line(empty_document.export_as_csv)
    expect(row).to eq(["", "", ""])
  end
end
