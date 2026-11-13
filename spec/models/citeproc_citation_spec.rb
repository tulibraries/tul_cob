# frozen_string_literal: true

require "rails_helper"

RSpec.describe CiteprocCitation do
  it "renders parenthetical fuller forms correctly across styles" do
    document = SolrDocument.new(
      "id" => "991006438039703811",
      "title_statement_display" => ["Example / Foo."],
      "creator_display" => ["Slayton, William L. (William Larew), 1916-|author"],
      "format" => ["Book"]
    )

    citations = described_class.new(document).citations

    expect(citations["APA"]).to include("Slayton, W. L. (W. L.).")
    expect(citations["CHICAGO-AUTHOR-DATE"]).to include("Slayton, William L. (William Larew).")
  end

  it "reuses rendered citations across repeated calls" do
    document = SolrDocument.new(
      "id" => "991006438039703811",
      "title_statement_display" => ["Example / Foo."],
      "creator_display" => ["Slayton, William L. (William Larew), 1916-|author"],
      "format" => ["Book"]
    )

    citation = described_class.new(document)

    first_result = citation.citations
    second_result = citation.citations

    expect(first_result).to equal(second_result)
    expect(first_result.keys).to match_array(described_class::STYLE_MAP.keys)
  end
end
