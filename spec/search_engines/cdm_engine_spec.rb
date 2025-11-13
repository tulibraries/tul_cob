# frozen_string_literal: true

require "rails_helper"

RSpec.describe BentoSearch::CDMEngine do
  subject(:engine) { described_class.new }

  describe "#view_link" do
    it "builds the full results link using the configured collection list" do
      helper = instance_double("ActionView::Base")
      allow(I18n).to receive(:t).with("bento.cdm_collections_list").and_return("photos")
      expected_url = "https://digital.library.temple.edu/digital/search/collection/photos"

      expect(helper).to receive(:link_to)
        .with("See all results", expected_url, class: "bento-full-results", target: "_blank")
        .and_return("<a>See all results</a>")

      expect(engine.view_link(123, helper)).to eq("<a>See all results</a>")
    end
  end
end
