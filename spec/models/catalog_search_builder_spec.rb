# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatalogSearchBuilder do
  let(:blacklight_config) do
    Blacklight::Configuration.new.tap do |config|
      config.default_solr_params = {
        qt: "search",
        "facet.field" => ["lc_classification"]
      }

      config.add_search_field("all_fields") do |field|
        field.solr_parameters = {
          qf: "text",
          pf: "title_statement_t^5",
          pf2: "title_t^3"
        }
      end
    end
  end

  let(:context) do
    double(
      "controller",
      blacklight_config: blacklight_config
    )
  end

  describe "query truncation" do
    let(:long_query) { Array.new(30, "term").join(" ") }

    let(:params) do
      {
        q: long_query,
        search_field: "all_fields"
      }
    end

    subject(:solr_params) do
      described_class
        .new(context)
        .with(params)
        .processed_parameters
    end

    it "truncates overlong keyword queries" do
      expect(solr_params[:q].split.length).to eq(
        described_class::MAX_QUERY_TOKENS
      )
    end

    it "preserves the original token order" do
      expected =
        long_query
          .split
          .first(described_class::MAX_QUERY_TOKENS)
          .join(" ")

      expect(solr_params[:q]).to eq(expected)
    end
  end

  describe "short queries" do
    let(:params) do
      {
        q: "short query",
        search_field: "all_fields"
      }
    end

    subject(:solr_params) do
      described_class
        .new(context)
        .with(params)
        .processed_parameters
    end

    it "does not modify short queries" do
      expect(solr_params[:q]).to eq("short query")
    end
  end

  describe "phrase boost suppression" do
    let(:params) do
      {
        q: Array.new(15, "term").join(" "),
        search_field: "all_fields"
      }
    end

    subject(:solr_params) do
      described_class
        .new(context)
        .with(params)
        .processed_parameters
    end

    it "removes phrase boosts for long queries" do
      expect(solr_params).not_to have_key("pf")
      expect(solr_params).not_to have_key("pf2")
    end
  end

  describe "phrase boosts for short queries" do
    let(:params) do
      {
        q: "civil war letters",
        search_field: "all_fields"
      }
    end

    subject(:solr_params) do
      described_class
        .new(context)
        .with(params)
        .processed_parameters
    end

    it "keeps phrase boosts for short queries" do
      expect(solr_params).to have_key("pf")
      expect(solr_params).to have_key("pf2")
    end
  end
end
