# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Citable" do
  let(:document) { SolrDocument.new("id" => "1", "title_statement_display" => ["Example Title"]) }

  context "when citeproc citations are enabled" do
    before do
      allow(Flipflop).to receive(:citeproc_citations?).and_return(true)
    end

    it "uses CiteprocCitation" do
      citeproc = instance_double(CiteprocCitation, citable?: true, citations: { "APA" => "Citation" })
      expect(CiteprocCitation).to receive(:new).with(document).and_return(citeproc)

      document.citations
    end
  end

  context "when citeproc citations are disabled" do
    before do
      allow(Flipflop).to receive(:citeproc_citations?).and_return(false)
    end

    it "still uses CiteprocCitation" do
      citeproc = instance_double(CiteprocCitation, citable?: true, citations: { "APA" => "Citation" })
      expect(CiteprocCitation).to receive(:new).with(document).and_return(citeproc)

      document.citations
    end
  end
end
