# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrimoCentralController, type: :controller do
  let(:search_service) { instance_double(Blacklight::SearchService) }

  describe "stale paginated article responses" do
    let(:empty_response) do
      Blacklight::PrimoCentral::Response.new(
        { "docs" => [], "facets" => [], "info" => { "total" => 0 } },
        { offset: 270 },
        blacklight_config: controller.blacklight_config,
        numFound: 0
      )
    end

    before do
      allow(controller).to receive(:search_service).and_return(search_service)
      allow(search_service).to receive(:search_results).and_return([empty_response, []])
    end

    it "redirects paginated searches with an expired-session flash" do
      get :index, params: { q: "albert pike", search_field: "any", page: 28 }

      expect(response).to redirect_to("/articles?q=albert+pike&search_field=any")
      expect(flash[:stale_article_results_restart]).to eq(true)
    end

    it "renders first-page zero results normally" do
      get :index, params: { q: "albert pike", search_field: "any" }

      expect(response).to have_http_status(:ok)
      expect(response).not_to be_redirect
    end
  end
end
