# frozen_string_literal: true

require "rails_helper"

RSpec.describe BentoSearch::JournalsEngine do
  subject(:engine) { described_class.new }

  describe "#doc_link" do
    it "builds the journal document path" do
      expect(engine.doc_link("123")).to eq("/journals/123")
    end
  end

  describe "#url" do
    it "builds a journals search path with only the query parameter" do
      helper = instance_double("ViewHelper", params: { q: "biology", page: "2" })

      expect(helper).to receive(:search_journals_path).with({ q: "biology" })
        .and_return("/journals?q=biology")

      expect(engine.url(helper)).to eq("/journals?q=biology")
    end
  end

  describe "#view_link" do
    it "renders a link to all journal results" do
      helper = instance_double("ViewHelper")
      expected_url = "/journals?q=biology"

      allow(engine).to receive(:url).with(helper).and_return(expected_url)
      expect(helper).to receive(:link_to)
        .with("See all 12 results", expected_url, class: "bento-full-results bento_journals_header")
        .and_return("<a>See all 12 results</a>")

      expect(engine.view_link(12, helper)).to eq("<a>See all 12 results</a>")
    end
  end
end
