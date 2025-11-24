# frozen_string_literal: true

require "rails_helper"

RSpec.describe BentoSearch::CDMEngine do
  subject(:engine) { described_class.new }

  describe "#view_link" do
    let(:collection_ids) { Array.wrap(Rails.configuration.cdm&.dig(:collection_ids)) }
    let(:first_collection) { collection_ids.first }
    let(:base_url) { I18n.t("bento.cdm.base_url") }

    it "uses 'See all results' text when totals are present" do
      helper = double("ViewHelper")
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(q: "cat"))
      expected_url = "#{base_url}/digital/search/collection/#{first_collection}/searchterm/cat/order/nosort"
      allow(helper).to receive(:cdm_results_link).with("cat").and_return(expected_url)

      expect(helper).to receive(:link_to)
        .with("See all results", expected_url, class: "bento-full-results", target: "_blank")
        .and_return("<a>See all results</a>")

      expect(engine.view_link(123, helper)).to eq("<a>See all results</a>")
    end

    it "falls back to 'Browse all digitized collections' when totals are missing" do
      helper = double("ViewHelper")
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new)
      expected_url = base_url
      allow(helper).to receive(:cdm_base_link).and_return(expected_url)

      expect(helper).to receive(:link_to)
        .with("Browse all digitized collections", expected_url, class: "bento-full-results", target: "_blank")
        .and_return("<a>Browse all digitized collections</a>")

      expect(engine.view_link(nil, helper)).to eq("<a>Browse all digitized collections</a>")
    end
  end
end
