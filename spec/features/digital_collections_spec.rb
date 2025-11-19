# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Digital Collections" do
  let(:search_query) { "art history" }
  let(:cdm_results) do
    VCR.use_cassette("bento_search_cdm") do
      BentoSearch.get_engine("cdm").search(search_query)
    end
  end
  let(:searcher_results) { { "cdm" => cdm_results } }
  let(:searcher_double) do
    instance_double(BentoSearch::ConcurrentSearcher, search: nil, results: searcher_results)
  end
  let(:empty_response) do
    format_facet = instance_double("Facet", items: [])
    aggregations = ActiveSupport::HashWithIndifferentAccess.new("format" => format_facet)
    instance_double("Blacklight::Solr::Response", aggregations: aggregations)
  end

  before do
    allow(BentoSearch::ConcurrentSearcher).to receive(:new).and_return(searcher_double)
    allow_any_instance_of(SearchController).to receive(:process_results) do |controller, results|
      controller.instance_variable_set(:@response, empty_response)
      results
    end
  end

  scenario "shows the ContentDM collection name for a matched alias" do
    visit "/bento"

    within("div.input-group") do
      fill_in "q", with: search_query
      click_button
    end

    container_selector = ".cdm-results-container, .cdm-results-container-new"
    expect(page).to have_css(container_selector)

    within(first(container_selector)) do
      expect(page).to have_text("Temple University Yearbooks")
    end
  end
end
