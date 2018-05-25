# frozen_string_literal: true

require "rails_helper"
require "rake"
Rails.application.load_tasks

RSpec.describe CatalogController, :focus, type: :controller, relevance: true do
  render_views

  before(:all) do
    Rake::Task["fortytu:solr:load_fixtures"].invoke("#{SPEC_ROOT}/relevance/fixtures/*.xml")
  end

  let(:response) { JSON.parse(get(:index, params: { q: search_term, per_page: 100 }, format: "json").body) }

  describe "a search for" do


  context "epistemic injustice" do
    let(:search_term) { "epistemic injustice" }

    it "has expected results before a less relevant result" do
      expect(response)
        .to include_docs(%w[991024847639703811 991024847639703811 991033452769703811])
        .before(["991036813237303811"])
    end
  end

  context "Cabinet of Caligari" do
  let(:search_term) { "Cabinet of Caligari" }

  it "has expected results before a less relevant result" do
    expect(response)
      .to include_docs(%w[991020778949703811 991001777289703811 991027229969703811 991001812089703811])
      .before(["991029142769703811"])
  end
end
end
end
