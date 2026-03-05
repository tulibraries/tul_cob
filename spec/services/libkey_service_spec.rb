# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

RSpec.describe LibkeyService, type: :service do
  let(:config) do
    {
      base_url: "https://public-api.thirdiron.com/public/v1/libraries",
      library_id: "130",
      apikey: "secret-token"
    }.with_indifferent_access
  end
  let(:cache_config) { { libkey_article_cache_life: "PT12H" }.with_indifferent_access }
  let(:service) { described_class.new(config:, cache_config:) }

  around do |example|
    previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = previous_cache
  end

  before do
    allow(Primo::Search).to receive(:with_retry).and_yield
  end

  describe "#article_data_thread_for_doi" do
    it "returns empty data when doi is blank" do
      expect(service.article_data_thread_for_doi(nil).value).to be_nil
    end

    it "returns libkey article data" do
      stub_request(:get, "https://public-api.thirdiron.com/public/v1/libraries/130/articles/doi/10.1234/foo?access_token=secret-token")
        .to_return(
          status: 200,
          body: JSON.dump(data: {
            fullTextFile: "https://example.org/full-text",
            contentLocation: "https://example.org/content",
            ignoredField: "ignored"
          }),
          headers: { "Content-Type" => "application/json" }
        )

      result = service.article_data_thread_for_doi("10.1234/foo").value
      expect(result).to eq(
        "fullTextFile" => "https://example.org/full-text",
        "contentLocation" => "https://example.org/content"
      )
    end

    it "caches article responses by doi" do
      url = "https://public-api.thirdiron.com/public/v1/libraries/130/articles/doi/10.5678/bar?access_token=secret-token"
      stub_request(:get, url)
        .to_return(
          status: 200,
          body: JSON.dump(data: { fullTextFile: "https://example.org/full-text" }),
          headers: { "Content-Type" => "application/json" }
        )

      expect(service.article_data_thread_for_doi("10.5678/bar").value).to eq(
        "fullTextFile" => "https://example.org/full-text"
      )
      expect(service.article_data_thread_for_doi("10.5678/bar").value).to eq(
        "fullTextFile" => "https://example.org/full-text"
      )
      expect(a_request(:get, url)).to have_been_made.once
    end
  end

  describe "#journal_data_thread_for_display_issns" do
    it "returns empty data when issn values are blank" do
      expect(service.journal_data_thread_for_display_issns([]).value).to be_nil
    end

    it "normalizes issns and returns journal data" do
      url = "https://public-api.thirdiron.com/public/v1/libraries/130/search?issns=12345678,87654321&access_token=secret-token"
      stub_request(:get, url)
        .to_return(
          status: 200,
          body: JSON.dump(data: [
            {
              browzineEnabled: true,
              browzineWebLink: "https://browzine.example.org",
              ignoredField: "ignored"
            }
          ]),
          headers: { "Content-Type" => "application/json" }
        )

      result = service.journal_data_thread_for_display_issns(["1234-5678", "8765-4321", "1234-5678"]).value
      expect(result).to eq(
        "browzineEnabled" => true,
        "browzineWebLink" => "https://browzine.example.org"
      )
    end
  end
end
