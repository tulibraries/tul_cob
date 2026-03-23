# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Articles pagination after idle time" do
  include ActiveSupport::Testing::TimeHelpers

  let(:query) { "albert pike" }
  let(:success_response_body) { articles_response(total: 1343, first: 261, last: 270) }
  let(:empty_response_body) { articles_response(total: 0, first: 0, last: 0, docs: [], facets: []) }

  before do
    stub_request(:get, /primo/).to_return do |request|
      offset = Rack::Utils.parse_nested_query(URI(request.uri).query)["offset"]

      body =
        case offset
        when "260"
          success_response_body
        when "270"
          empty_response_body
        else
          success_response_body
        end

      {
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body:
      }
    end
  end

  scenario "shows the zero-results state after clicking next from a later page" do
    travel_to(Time.zone.local(2026, 3, 23, 10, 0, 0)) do
      visit "/articles?search_field=any&q=#{CGI.escape(query)}&page=27"

      expect(page).to have_text("261 - 270 of 1,343")
      expect(page).to have_link("Next »")
      expect(page).not_to have_text("No article results found for your search.")
    end

    travel_to(Time.zone.local(2026, 3, 23, 10, 30, 0)) do
      all(:link, "Next »", visible: true).last.click

      expect(page).to have_current_path(/page=28/)
      expect(page).to have_text("No article results found for your search.")
    end
  end

  def articles_response(total:, first:, last:, docs: nil, facets: nil)
    payload = JSON.parse(File.read(Rails.root.join("spec/fixtures/articles_search_response.json")))
    payload["info"]["total"] = total
    payload["info"]["totalResultsPC"] = total
    payload["info"]["first"] = first
    payload["info"]["last"] = last
    payload["docs"] = docs unless docs.nil?
    payload["facets"] = facets unless facets.nil?
    payload.to_json
  end
end
