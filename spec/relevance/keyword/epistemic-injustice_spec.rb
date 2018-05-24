# frozen_string_literal: true

RSpec.describe CatalogController, :focus, type: :controller, relevance: true do

  describe "returns relevant results in teh right order" do
    render_views

    before do
      system("bundle exec rake ingest[#{SPEC_ROOT}/relevance/fixtures/epistemic-injustice.xml]")
      @response = JSON.parse(get(:index, params: { q: search_term, per_page: 100 }, format: "json").body)
    end

    describe "searching for epistemic injustice" do
      let(:search_term) { "epistemic injustice" }


      it "has expected results before a less relevant result" do
        expect(@response).to include_docs(%w[991036802546303811 991024847639703811]).before(["991036813237303811"])
      end
    end
  end
end
