# frozen_string_literal: true

require "rails_helper"

RSpec.describe Citeproc::ItemService do
  subject(:item) { described_class.build(document) }

  let(:document) do
    SolrDocument.new(
      "id" => "991012041239703811",
      "title_statement_display" => ["Big mechanisms in systems biology : big data mining, network modeling, and genome-wide data identification / Bor-Sen Chen, Cheng-Wei Li."],
      "creator_display" => ["Chen, Bor-Sen|author."],
      "contributor_display" => ["Li, Zhengwei|author."],
      "format" => ["Book"]
    )
  end

  def citeproc_names(value)
    value&.to_citeproc
  end

  it "builds a citeproc item from indexed title and relator-normalized names" do
    expect(item.id).to eq("991012041239703811")
    expect(item.type).to eq("book")
    expect(item.title).to eq("Big mechanisms in systems biology : big data mining, network modeling, and genome-wide data identification")
    expect(citeproc_names(item.author)).to eq([{ "family" => "Chen", "given" => "Bor-Sen" }, { "family" => "Li", "given" => "Zhengwei" }])
  end

  it "restores the legacy citation item attributes" do
    document["imprint_display"] = ["Philadelphia : Temple University Press, 2021"]
    document["pub_date_display"] = ["2021"]
    document["isbn_display"] = ["9781439912345"]
    document["issn_display"] = ["1234-5678"]

    expect(item.issued.to_citeproc).to eq("date-parts" => [[2021]])
    expect(item.publisher).to eq("Temple University Press")
    expect(item["publisher_place"]).to eq("Philadelphia")
    expect(item["ISBN"]).to eq("9781439912345")
    expect(item["ISSN"]).to eq("1234-5678")
  end

  it "maps supported contributor relators from indexed fields" do
    document["contributor_display"] = [
      "Norris, Denne Michele,|editor.",
      "Diaz, Ana|http://id.loc.gov/vocabulary/relators/trl",
      "Example Press|illustrator."
    ]

    expect(citeproc_names(item.editor)).to eq([{ "family" => "Norris", "given" => "Denne Michele" }])
    expect(citeproc_names(item.translator)).to eq([{ "family" => "Diaz", "given" => "Ana" }])
    expect(citeproc_names(item.illustrator)).to eq([{ "literal" => "Example Press" }])
  end

  it "parses contributor-only json indexed values" do
    document["creator_display"] = []
    document["contributor_display"] = [
      '{"relation":"","name":"Norris, Denne Michele","role":"editor"}'
    ]

    expect(citeproc_names(item.editor)).to eq([{ "family" => "Norris", "given" => "Denne Michele" }])
  end

  it "parses author relators from contributor-only json indexed values" do
    document["creator_display"] = []
    document["contributor_display"] = [
      '{"relation":"","name":"Example, Avery","role":"author"}'
    ]

    expect(citeproc_names(item.author)).to eq([{ "family" => "Example", "given" => "Avery" }])
  end

  it "uses contributor_display as author when there is no creator_display" do
    document["creator_display"] = []
    document["contributor_display"] = [
      "Norris, Denne Michele,"
    ]

    expect(citeproc_names(item.author)).to eq([{ "family" => "Norris", "given" => "Denne Michele" }])
  end

  it "returns nil when indexed title data is missing" do
    document["title_statement_display"] = []
    document["title_with_subtitle_display"] = []
    document["title_with_subtitle_truncated_display"] = []

    expect(item).to be_nil
  end

  it "treats creator_display as author when there is no relator" do
    document["creator_display"] = ["World Health Organization."]
    document["contributor_display"] = []

    expect(citeproc_names(item.author)).to eq([{ "literal" => "World Health Organization" }])
  end

  it "defaults unsupported creator relators to author" do
    document["creator_display"] = ["Norris, Denne Michele,|writer of supplementary textual content."]
    document["contributor_display"] = []

    expect(citeproc_names(item.author)).to eq([{ "family" => "Norris", "given" => "Denne Michele" }])
  end

  it "strips life dates from indexed personal names" do
    document["creator_display"] = ["Boswell, James, 1740-1795"]
    document["contributor_display"] = []

    expect(citeproc_names(item.author)).to eq([{ "family" => "Boswell", "given" => "James" }])
  end

  it "strips life dates when the indexed personal name ends with punctuation" do
    document["creator_display"] = ["Pong, Chun-ho, 1969-."]
    document["contributor_display"] = []

    expect(citeproc_names(item.author)).to eq([{ "family" => "Pong", "given" => "Chun-ho" }])
  end

  it "strips parenthesized life dates from indexed personal names" do
    document["creator_display"] = ["Example, Avery (1969-)"]
    document["contributor_display"] = []

    expect(citeproc_names(item.author)).to eq([{ "family" => "Example", "given" => "Avery" }])
  end

  it "strips a trailing standalone year from indexed personal names" do
    document["creator_display"] = ["Example, Avery, 1969"]
    document["contributor_display"] = []

    expect(citeproc_names(item.author)).to eq([{ "family" => "Example", "given" => "Avery" }])
  end

  it "strips trailing meeting metadata from literal names" do
    document["creator_display"] = ["International Society on Oxygen Transport to Tissue. Annual Meeting (36th : 2008 : Sapporo-shi, Japan)"]
    document["contributor_display"] = []

    expect(citeproc_names(item.author)).to eq([{ "literal" => "International Society on Oxygen Transport to Tissue. Annual Meeting" }])
  end

  it "strips trailing meeting metadata from json indexed literal names" do
    document["creator_display"] = ['{"relation":"","name":"International Society on Oxygen Transport to Tissue. Annual Meeting (36th : 2008 : Sapporo-shi, Japan)","role":"author"}']
    document["contributor_display"] = []

    expect(citeproc_names(item.author)).to eq([{ "literal" => "International Society on Oxygen Transport to Tissue. Annual Meeting" }])
  end

  it "strips unparenthesized trailing meeting metadata from literal names" do
    document["creator_display"] = ["International Society on Oxygen Transport to Tissue. Annual Meeting 36th : 2008 : Sapporo-shi, Japan"]
    document["contributor_display"] = []

    expect(citeproc_names(item.author)).to eq([{ "literal" => "International Society on Oxygen Transport to Tissue. Annual Meeting" }])
  end

  it "strips compact trailing meeting metadata from literal names" do
    document["creator_display"] = ["International Society on Oxygen Transport to Tissue. Annual Meeting (36th: 2008: Sapporo-shi, Japan)"]
    document["contributor_display"] = []

    expect(citeproc_names(item.author)).to eq([{ "literal" => "International Society on Oxygen Transport to Tissue. Annual Meeting" }])
  end

  it "treats multi-comma non-personal names as literals" do
    document["creator_display"] = ["International Society on Oxygen Transport to Tissue. Annual Meeting, Sapporo-shi, Japan"]
    document["contributor_display"] = []

    expect(citeproc_names(item.author)).to eq([{ "literal" => "International Society on Oxygen Transport to Tissue. Annual Meeting, Sapporo-shi, Japan" }])
  end

  it "ignores contributor_display entries without supported relators when creator_display is present" do
    document["creator_display"] = ["Primary, Pat|author."]
    document["contributor_display"] = [
      "Contributor, Chris.",
      "Helper, Pat|writer of supplementary textual content."
    ]

    expect(citeproc_names(item.author)).to eq([{ "family" => "Primary", "given" => "Pat" }])
    expect(item.editor).to be_nil
    expect(item.translator).to be_nil
  end
end
