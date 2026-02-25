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

  describe ".quik_pay" do
    it "prefers credentials over config values" do
      allow(described_class).to receive(:credentials_value)
        .with([:quik_pay, :url])
        .and_return("https://credentials.example")
      allow(Rails.configuration).to receive(:quik_pay).and_return({ url: "https://config.example" }.with_indifferent_access)

      expect(described_class.quik_pay(:url)).to eq("https://credentials.example")
    end

    it "falls back to config values when credentials are not set" do
      allow(described_class).to receive(:credentials_value)
        .with([:quik_pay, :url])
        .and_return(nil)
      allow(Rails.configuration).to receive(:quik_pay).and_return({ url: "https://config.example" }.with_indifferent_access)

      expect(described_class.quik_pay(:url)).to eq("https://config.example")
    end
  end

  describe ".saml" do
    it "falls back to devise config values when credentials are not set" do
      allow(described_class).to receive(:credentials_value)
        .with([:saml, :sign_out_redirect_url])
        .and_return(nil)
      allow(Rails.configuration).to receive(:devise).and_return({ sign_out_redirect_url: "/shib-logout" }.with_indifferent_access)

      expect(described_class.saml(:sign_out_redirect_url)).to eq("/shib-logout")
    end
  end

  describe ".smtp_asktulib_password" do
    it "prefers credentials over environment values" do
      allow(described_class).to receive(:credentials_value)
        .with([:smtp, :asktulib_password])
        .and_return("credentials-smtp-pass")
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("ASKTULIB_PASSWORD").and_return("env-smtp-pass")

      expect(described_class.smtp_asktulib_password).to eq("credentials-smtp-pass")
    end

    it "falls back to environment when credentials are not set" do
      allow(described_class).to receive(:credentials_value)
        .with([:smtp, :asktulib_password])
        .and_return(nil)
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("ASKTULIB_PASSWORD").and_return("env-smtp-pass")

      expect(described_class.smtp_asktulib_password).to eq("env-smtp-pass")
    end
  end

  describe ".microsoft_graph_mailer" do
    it "prefers credentials over config values" do
      allow(described_class).to receive(:credentials_value)
        .with([:microsoft_graph_mailer, :tenant_id])
        .and_return("credentials-tenant")
      allow(Rails.configuration).to receive(:microsoft_graph_mailer).and_return({ tenant_id: "config-tenant" }.with_indifferent_access)

      expect(described_class.microsoft_graph_mailer(:tenant_id)).to eq("credentials-tenant")
    end

    it "falls back to config values when credentials are not set" do
      allow(described_class).to receive(:credentials_value)
        .with([:microsoft_graph_mailer, :tenant_id])
        .and_return(nil)
      allow(Rails.configuration).to receive(:microsoft_graph_mailer).and_return({ tenant_id: "config-tenant" }.with_indifferent_access)

      expect(described_class.microsoft_graph_mailer(:tenant_id)).to eq("config-tenant")
    end
  end
end
