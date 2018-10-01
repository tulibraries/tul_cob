# frozen_string_literal: true

require "rails_helper"
require "spec_helper"

module StubOclcResponse
  def stub_oclc_response(response, opts = {})
    allow_any_instance_of(Citation).to receive(:field).and_return(opts[:for]) if opts[:for]
    allow_any_instance_of(Citation).to receive(:response).and_return(response)
  end
end

RSpec.configure do |config|
  config.include StubOclcResponse
end

RSpec.describe Citation, type: :model do
  subject { described_class.new(document, formats) }
  let(:citations) do
    [
      "<p class='citation_style_MLA'>MLA Citation</p>",
      "<p class='citation_style_APA'>APA Citation</p>"
    ]
  end


  describe "#citable?" do
    context "when there is no oclc number" do
      let(:formats) { [] }
      let(:document) { SolrDocument.new(subject_display: "No OCLC") }
      it "is false" do
        expect(subject).to_not be_citable
      end
    end

    context "when there is an oclc number" do
      let(:formats) { [] }
      let(:document) { SolrDocument.new(oclc_number_display: "12345") }
      it "is true" do
        expect(subject).to be_citable
      end
    end
  end

  describe "#citations" do
    context "when there is no data returned from OCLC" do
      let(:formats) { [] }
      let(:document) { SolrDocument.new(oclc_number_display: "") }

      it "returns the NULL citation" do
        expect(subject.citations["NULL"]).to eq "<p>No citation available for this record</p>"
      end
    end

    context "when all formats are requested" do
      let(:document) { SolrDocument.new(oclc_number_display: "12345") }
      let(:formats) { ["ALL"] }
      let(:oclc_response) { citations.join }
      let(:stub_opts) { {} }
      before { stub_oclc_response(oclc_response, stub_opts) }

      it "all formats from the OCLC response are returned" do
        expect(subject.citations["MLA"]).to match %r{^<p class=.*>MLA Citation</p>$}
        expect(subject.citations["APA"]).to match %r{^<p class=.*>APA Citation</p>$}
      end
    end
  end

  describe "#api_url" do
    let(:formats) { ["ALL"] }
    let(:document) { SolrDocument.new(oclc_number_display: "12345") }
    it "returns a URL with the given document field" do
      expect(subject.send(:api_url)).to match %r{/citations/12345\?cformat=all}
    end
  end

  describe ".grouped_citations" do
    it "groups the citations based on their format" do
      citations = [
        { "APA" => "APA Citation1" },
        { "MLA" => "MLA Citation1" },
        { "APA" => "APA Citation2" }
      ]

      grouped_citations = described_class.grouped_citations(citations)
      expect(grouped_citations.keys.length).to eq 2
      expect(grouped_citations["APA"]).to eq ["APA Citation1", "APA Citation2"]
      expect(grouped_citations["MLA"]).to eq ["MLA Citation1"]
    end
  end
end
