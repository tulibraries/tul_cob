# frozen_string_literal: true

require "rails_helper"

RSpec.describe BentoSearch::CDMEngine do
  subject(:engine) { described_class.new }

  describe "#view_link" do
    let(:collection_ids) { ["photos"] }

    before do
      @original_cdm_config = Rails.configuration.cdm
      Rails.configuration.cdm = { collection_ids: collection_ids }.with_indifferent_access
    end

    after do
      Rails.configuration.cdm = @original_cdm_config
    end

    it "uses 'See all results' text when totals are present" do
      helper = instance_double("ActionView::Base")
      expected_url = "https://digital.library.temple.edu/digital/search/collection/photos"

      expect(helper).to receive(:link_to)
        .with("See all results", expected_url, class: "bento-full-results", target: "_blank")
        .and_return("<a>See all results</a>")

      expect(engine.view_link(123, helper)).to eq("<a>See all results</a>")
    end

    it "falls back to 'Browse all digitized collections' when totals are missing" do
      helper = instance_double("ActionView::Base")
      expected_url = "https://digital.library.temple.edu/digital/search/collection/photos"

      expect(helper).to receive(:link_to)
        .with("Browse all digitized collections", expected_url, class: "bento-full-results", target: "_blank")
        .and_return("<a>Browse all digitized collections</a>")

      expect(engine.view_link(nil, helper)).to eq("<a>Browse all digitized collections</a>")
    end
  end
end
