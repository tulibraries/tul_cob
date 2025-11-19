# frozen_string_literal: true

require "rails_helper"

RSpec.describe "bento_search digital collections partials", type: :view do
  PARTIAL_PATHS = {
    "search/digital_collections" => Rails.root.join("app/views/search/_digital_collections.html.erb"),
    "search/digital_collections_new" => Rails.root.join("app/views/search/_digital_collections_new.html.erb")
  }.freeze

  PARTIAL_PATHS.each do |partial, path|
    next unless path.exist?
    describe partial do
      it "renders the CDM suggestions when no results exist" do
        assign(:results, { "cdm" => BentoSearch::Results.new })
        assign(:params, ActionController::Parameters.new(q: "test"))

        render partial: partial

        collections = I18n.t("bento.cdm_collections_list")
        encoded_query = { q: "test" }.to_query.split("=", 2).last
        cdm_link = I18n.t("bento.cdm_full_results_link", collections:, query: encoded_query)
        expect(rendered).to include(I18n.t("no_results.cdm_html", cdm_link: cdm_link))
      end
    end
  end
end
