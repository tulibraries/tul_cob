# frozen_string_literal: true

require "rails_helper"

RSpec.describe PrimoCentralHelper, type: :helper do
  let(:doc) { Hash.new }
  let(:document) { PrimoCentralDocument.new(doc) }

  before(:example) do
    @document = document
  end

  describe "#availability_link_partials" do
    context "document does not have a direct link" do
      it "returns only the online partial" do
        expect(availability_link_partials).to eq(["online"])
      end
    end

    context "document does have a direct link" do
      let(:doc) { ActiveSupport::HashWithIndifferentAccess.new(
        delivery: { availability: ["fulltext_linktorsrc"] }
      )}

      it "returns only the direc_link partial" do
        expect(availability_link_partials).to eq(["direct_link"])
      end
    end
  end

  describe "#index_buttons_partials" do
    context "document does not have a direct link" do
      it "returns only the online button partial" do
        expect(index_buttons_partials).to eq(["online_button"])
      end
    end

    context "document does have a direct link" do
      let(:doc) { ActiveSupport::HashWithIndifferentAccess.new(
        delivery: { availability: ["fulltext_linktorsrc"] }
      )}

      it "returns only the direc_link button partial" do
        expect(index_buttons_partials).to eq(["direct_link_button"])
      end
    end
  end

  describe "#document_link_label" do
    context "no link label found" do
      it "returns a default value when no direct link label is found" do
        expect(document_link_label).to eq("Link to Resource")
      end
    end
  end

  describe "#empty_article_response?(response)" do
    context "response has no results" do
      let(:response) { {
        "response" => { "numFound" => 0, "start" => 0, "docs" => [] },
        "facets" => [],
        "stats" => { "stats_fields" => {} } }
      }

      it "is true" do
        expect(empty_response?(response)).to be true
      end
    end

    context "response has no results" do
      let(:response) { {
        "response" => { "numFound" => 3, "start" => 0, "docs" => [] },
        "facets" => [],
        "stats" => { "stats_fields" => {} } }
      }

      it "is true" do
        expect(empty_response?(response)).to be false
      end
    end
  end

  describe "#primo_facet_names" do
    let(:facet_field_names) { ["tlevel", "rtype", "topic", "date", "creator", "language"] }

    context "filters out unwanted facets" do
      it "does not return the date, topic, or creator facets" do
        expect(primo_facet_names).to eq(["tlevel", "rtype", "language"])
      end
    end
  end
end
