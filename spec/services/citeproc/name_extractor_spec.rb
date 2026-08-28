# frozen_string_literal: true

require "rails_helper"
require "marc"

RSpec.describe Citeproc::NameExtractor do
  subject(:extractor) { described_class.new(document) }

  let(:document) do
    SolrDocument.new(
      "id" => "991012041239703811",
      "title_statement_display" => ["Example title / Foo."],
      "creator_display" => ["Chen, Bor-Sen|author."],
      "contributor_display" => ["Li, Zhengwei|author."],
      "format" => ["Book"]
    )
  end

  def entry_hashes(entries)
    entries.map { |entry| { name: entry.name, relators: entry.relators } }
  end

  it "extracts pipe-delimited creator and contributor values" do
    expect(entry_hashes(extractor.creator_entries)).to eq([
      { name: "Chen, Bor-Sen", relators: ["author."] }
    ])
    expect(entry_hashes(extractor.contributor_entries)).to eq([
      { name: "Li, Zhengwei", relators: ["author."] }
    ])
  end

  it "extracts json values" do
    document["creator_display"] = []
    document["contributor_display"] = [
      '{"relation":"","name":"Example, Avery","role":"author"}'
    ]

    expect(entry_hashes(extractor.contributor_entries)).to eq([
      { name: "Example, Avery", relators: ["author"] }
    ])
  end

  it "extracts html-rendered contributor values" do
    document["creator_display"] = []
    document["contributor_display"] = [
      '<a href="/catalog?f[creator_facet][]=Yates%2C+David%2C+1963-">Yates, David, 1963-</a> director'
    ]

    expect(entry_hashes(extractor.contributor_entries)).to eq([
      { name: "Yates, David, 1963-", relators: ["director"] }
    ])
  end

  it "falls back to semantic contributor values when display fields are absent" do
    document = SolrDocument.new(
      "id" => "991012041239703811",
      "title_statement_display" => ["Example title / Foo."],
      "creator" => [],
      "contributor" => ["Alpha, Ada", "Beta, Ben"],
      "format" => ["Book"]
    )

    extractor = described_class.new(document)

    expect(entry_hashes(extractor.contributor_entries)).to eq([
      { name: "Alpha, Ada", relators: [] },
      { name: "Beta, Ben", relators: [] }
    ])
  end

  it "falls back to marc 7xx values when indexed contributor fields are absent" do
    marc_record = MARC::Record.new
    marc_record.append(MARC::DataField.new("700", "1", " ", ["a", "Alpha, Ada"], ["e", "former owner"]))
    marc_record.append(MARC::DataField.new("710", "2", " ", ["a", "Beta Research Group"], ["e", "sponsor"]))

    document = double(
      "document",
      id: "991012041239703811",
      to_marc: marc_record
    )
    allow(document).to receive(:[]).with("creator_display").and_return([])
    allow(document).to receive(:[]).with("creator").and_return(nil)
    allow(document).to receive(:[]).with("contributor_display").and_return([])
    allow(document).to receive(:[]).with("contributor").and_return(nil)

    extractor = described_class.new(document)

    expect(entry_hashes(extractor.fallback_contributor_entries)).to eq([
      { name: "Alpha, Ada", relators: [] },
      { name: "Beta Research Group", relators: [] }
    ])
  end
end
