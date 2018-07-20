# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatalogController, type: :controller, relevance: true do
  render_views

  describe "a faceted search for Presser Listening Library " do
    let(:response) { JSON.parse(get(:index, params: { "f" => { "library_facet" => ["Presser Listening Library"] }, per_page: 100 }, format: "json").body) }


    it "has results with another library before before results only at presser" do
      expect(response)
        .to include_docs(%w[991025170559703811 991012972279703811 991036165169703811])
        .before(["991034751269703811"])
    end
  end
end
