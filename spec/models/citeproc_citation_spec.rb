# frozen_string_literal: true

require "rails_helper"
require "citeproc"

RSpec.describe CiteprocCitation, type: :model do
  let(:document) do
    SolrDocument.new(
      "id" => "991012041239703811",
      "title_statement_display" => ["Test Title"],
      "creator_display" => ["Doe, Jane"],
      "pub_date_display" => ["2020"],
      "format" => ["Book"]
    )
  end

  it "returns citations for the configured styles" do
    allow_any_instance_of(described_class).to receive(:render_style) do |_instance, _style_id, label|
      "<p class=\"citation_style_#{label}\">Citation</p>".html_safe
    end

    citations = described_class.new(document).citations

    expect(citations.keys).to contain_exactly(
      "APA",
      "CHICAGO-AUTHOR-DATE",
      "CHICAGO-NOTES-BIBLIOGRAPHY",
      "MLA"
    )

    citations.each do |format, citation|
      expect(citation).to include("citation_style_#{format}")
    end
  end
end
