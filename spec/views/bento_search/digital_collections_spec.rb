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
        assign(:params, { q: "test" }) if partial == "search/digital_collections"

        render partial: partial

        expect(rendered).to include(I18n.t("no_results.cdm_html"))
      end
    end
  end
end
