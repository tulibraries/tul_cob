# frozen_string_literal: true

require "rails_helper"

RSpec.describe IntegrationConfig do
  describe ".primo_api_key" do
    it "prefers credentials over environment and config values" do
      allow(described_class).to receive(:credentials_value)
        .with([:primo, :apikey])
        .and_return("credentials-primo-key")
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("PRIMO_API_KEY").and_return("env-primo-key")
      allow(Rails.configuration).to receive(:bento).and_return({ primo: { apikey: "config-primo-key" } }.with_indifferent_access)

      expect(described_class.primo_api_key).to eq("credentials-primo-key")
    end

    it "falls back to environment when credentials are not set" do
      allow(described_class).to receive(:credentials_value)
        .with([:primo, :apikey])
        .and_return(nil)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("PRIMO_API_KEY").and_return("env-primo-key")
      allow(Rails.configuration).to receive(:bento).and_return({ primo: { apikey: "config-primo-key" } }.with_indifferent_access)

      expect(described_class.primo_api_key).to eq("env-primo-key")
    end

    it "falls back to config when credentials and environment are not set" do
      allow(described_class).to receive(:credentials_value)
        .with([:primo, :apikey])
        .and_return(nil)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("PRIMO_API_KEY").and_return(nil)
      allow(Rails.configuration).to receive(:bento).and_return({ primo: { apikey: "config-primo-key" } }.with_indifferent_access)

      expect(described_class.primo_api_key).to eq("config-primo-key")
    end
  end

  describe ".archives_space_open_timeout" do
    it "uses a credentials value when present" do
      allow(described_class).to receive(:credentials_value)
        .with([:archives_space, :open_timeout])
        .and_return("9")
      allow(ENV).to receive(:fetch).and_call_original

      expect(described_class.archives_space_open_timeout).to eq(9)
    end

    it "falls back to default when timeout is invalid" do
      allow(described_class).to receive(:credentials_value)
        .with([:archives_space, :open_timeout])
        .and_return(nil)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("ARCHIVESSPACE_OPEN_TIMEOUT", "2").and_return("bad")

      expect(described_class.archives_space_open_timeout).to eq(2)
    end
  end
end
