# frozen_string_literal: true

require "rails_helper"
require "webmock/rspec"

VCR.configure do |c|
  c.ignore_hosts "scrcarchivesspace.temple.edu"
end

RSpec.describe ArchivesSpaceService, type: :service do
  let(:username) { "api_librarysearch" }
  let(:password) { "secret" }
  let(:base_url) { "https://scrcarchivesspace.temple.edu/staff/api" }
  let(:service)  { described_class.new }

  # Always isolate Rails.cache per example
  around do |example|
    previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = previous_cache
  end

  before(:all) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  before do
    stub_const("ArchivesSpaceService::USERNAME", username)
    stub_const("ArchivesSpaceService::PASSWORD", password)
    stub_const("ArchivesSpaceService::BASE_URL", base_url)

    # Universal stub for login endpoint (matches /api or /staff/api)
    stub_request(:post, %r{https://scrcarchivesspace\.temple\.edu/.*/users/#{username}/login})
      .to_return(status: 200, body: { session: "abc123" }.to_json)
  end

  describe "#refresh_token!" do
    it "confirms WebMock intercepts POST" do
      response = Faraday.post("#{base_url}/users/#{username}/login")
      expect(response.status).to eq(200)
    end

    it "returns a session token" do
      expect(service.refresh_token!).to eq("abc123")
    end

    it "caches the token and expiry" do
      service.refresh_token!
      token_data = Rails.cache.read("aspace_session_token_data")
      expect(token_data).not_to be_nil
      expect(token_data[:token] || token_data["token"]).to eq("abc123")
    end
  end

  describe "#ensure_token!" do
    context "when cache is empty" do
      it "calls refresh_token! and returns a new token" do
        allow(service).to receive(:refresh_token!).and_return("newtoken")
        expect(service.send(:ensure_token!)).to eq("newtoken")
      end
    end

    context "when cached token is still valid" do
      before do
        Rails.cache.write(
          "aspace_session_token_data",
          { token: "cachedtoken", expires_at: 30.minutes.from_now }
        )
      end

      it "returns cached token without refreshing" do
        expect(service).not_to receive(:refresh_token!)
        expect(service.send(:ensure_token!)).to eq("cachedtoken")
      end
    end
  end

  describe "#search" do
    let(:token) { "abc123" }
    let(:records) { [{ "title" => "Temple Collection" }] }
    let(:response_body) { { results: records }.to_json }

    before do
      Rails.cache.write(
        "aspace_session_token_data",
        { token: token, expires_at: 30.minutes.from_now }
      )

      stub_request(:get, "#{base_url}/search")
        .with(
          headers: { "X-ArchivesSpace-Session" => token },
          query: hash_including("q" => "Temple University")
        )
        .to_return(status: 200, body: response_body)
    end

    it "returns parsed results from the API" do
      results = service.search("Temple University")
      expect(results).to be_an(Array)
      expect(results.first["title"]).to eq("Temple Collection")
    end

    it "refreshes the token and retries when unauthorized" do
      allow(service).to receive(:ensure_token!).and_return("oldtoken")
      expect(service).to receive(:refresh_token!).and_return("newtoken")

      stub_request(:get, "#{base_url}/search")
        .with(
          headers: { "X-ArchivesSpace-Session" => "oldtoken" },
          query: hash_including("q" => "Temple University")
        )
        .to_return(status: 401, body: "unauthorized", headers: { "Content-Type" => "text/plain" })

      stub_request(:get, "#{base_url}/search")
        .with(
          headers: { "X-ArchivesSpace-Session" => "newtoken" },
          query: hash_including("q" => "Temple University")
        )
        .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })

      results = service.search("Temple University")
      expect(results.first["title"]).to eq("Temple Collection")
    end

    it "raises a helpful error when response is not JSON" do
      stub_request(:get, "#{base_url}/search")
        .with(
          headers: { "X-ArchivesSpace-Session" => token },
          query: hash_including("q" => "Temple University")
        )
        .to_return(status: 200, body: "<html>oops</html>", headers: { "Content-Type" => "text/html" })

      expect { service.search("Temple University") }
        .to raise_error(RuntimeError, /non-JSON content-type/)
    end
  end
end
