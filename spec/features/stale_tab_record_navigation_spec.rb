# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Stale tab record navigation" do
  include ActiveSupport::Testing::TimeHelpers

  let(:doc_id) { "991034781679703811" }
  let(:solr_response) { instance_double(Blacklight::Solr::Response, total: 1, more_like: [], :[] => {}) }
  let(:solr_document) { SolrDocument.new({ "id" => doc_id }, solr_response) }

  scenario "user can click a record from an aged results tab without landing on a 500 page" do
    allow_any_instance_of(Blacklight::SearchService)
      .to receive(:fetch)
      .and_return([solr_response, solr_document])

    search = Search.create!(query_params: { q: "otter" })

    travel_to(Time.zone.local(2026, 1, 22, 10, 0, 0)) do
      page.driver.submit(:post, "/catalog/#{doc_id}/track", {
        counter: "98",
        document_id: doc_id,
        search_id: search.id.to_s,
        per_page: "10"
      })
    end

    search.destroy!

    travel_to(Time.zone.local(2026, 1, 22, 13, 0, 0)) do
      visit "/catalog/#{doc_id}"
      expect(current_path).to eq("/catalog/#{doc_id}")

      # Guard against known failure pages
      expect(page).not_to have_text("Internal Server Error")
      expect(page).not_to have_text("The requested URL was rejected")
    end
  end
end
