# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Articles pagination after idle time" do
  include ActiveSupport::Testing::TimeHelpers

  let(:query) { "albert pike" }
  let(:session_expired_message) { I18n.t("articles.stale_session.message") }
  let(:success_response_body) { articles_response(total: 1343, first: 261, last: 270) }
  let(:empty_response_body) { articles_response(total: 0, first: 0, last: 0, docs: [], facets: []) }
  let(:restarted_first_page_response_body) { articles_response(total: 1343, first: 1, last: 10) }

  before do
    allow_any_instance_of(PrimoCentralController).to receive(:find_or_initialize_search_session_from_params).and_return(nil)
    allow_any_instance_of(PrimoCentralController).to receive(:render_bookmarks_control?).and_return(false)

    stub_request(:get, /primo/).to_return do |request|
      offset = Rack::Utils.parse_nested_query(URI(request.uri).query)["offset"]

      body =
        case offset
        when "0"
          restarted_first_page_response_body
        when "260"
          success_response_body
        when "270"
          empty_response_body
        else
          restarted_first_page_response_body
        end

      {
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body:
      }
    end
  end

  context "when the restarted first page returns results again" do
    let(:restarted_first_page_response_body) { articles_response(total: 1343, first: 1, last: 10) }

    scenario "redirects back to the first page when a later page returns a stale upstream empty response" do
      travel_to(Time.zone.local(2026, 3, 23, 10, 0, 0)) do
        visit "/articles?search_field=any&q=#{CGI.escape(query)}&page=27"

        expect(page).to have_text("261 - 270 of 1,343")
        expect(page).to have_link("Next »")
        expect(page).not_to have_text("No article results found for your search.")
      end

      travel_to(Time.zone.local(2026, 3, 23, 10, 30, 0)) do
        all(:link, "Next »", visible: true).last.click

        uri = URI.parse(current_url)

        expect(uri.path).to eq("/articles")
        expect(CGI.parse(uri.query)).to eq({ "q" => ["albert pike"], "search_field" => ["any"] })
        expect(page).to have_text(session_expired_message)
        expect(page).to have_text("1 - 10 of 1,343")
        expect(page).not_to have_text("No article results found for your search.")
      end
    end
  end

  context "when the restarted first page is still empty" do
    let(:restarted_first_page_response_body) { empty_response_body }

    scenario "suppresses the misleading zero-results message when the restarted first page is also empty" do
      travel_to(Time.zone.local(2026, 3, 23, 10, 0, 0)) do
        visit "/articles?search_field=any&q=#{CGI.escape(query)}&page=27"

        expect(page).to have_text("261 - 270 of 1,343")
        expect(page).to have_link("Next »")
        expect(page).not_to have_text("No article results found for your search.")
      end

      travel_to(Time.zone.local(2026, 3, 23, 10, 30, 0)) do
        all(:link, "Next »", visible: true).last.click

        uri = URI.parse(current_url)

        expect(uri.path).to eq("/articles")
        expect(CGI.parse(uri.query)).to eq({ "q" => ["albert pike"], "search_field" => ["any"] })
        expect(page).to have_text(session_expired_message)
        expect(page).to have_text("Are you looking for scholarly journal articles? Try:")
        expect(page).to have_link("Databases Search")
        expect(page).not_to have_text("No article results found for your search.")
        expect(page).not_to have_text("1 - 10 of")
      end
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
