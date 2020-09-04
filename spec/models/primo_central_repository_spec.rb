# frozen_string_literal: true

require "rails_helper"


RSpec.describe Blacklight::PrimoCentral::Repository , type: :model do
  let(:config) { PrimoCentralController.blacklight_config }
  let(:repo) { Blacklight::PrimoCentral::Repository.new(config) }

  subject { repo }

  describe ".search" do
    context "skip_search? true" do
      it "returns empty response" do
        expect(subject.search(skip_search?: true)).to eq(
          {
            "response" => { "numFound" => 0, "start" => 0, "docs" => [] },
            "facets" => [],
            "stats" => { "stats_fields" => {} } }
        )
      end
    end
  end
end
