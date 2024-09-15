# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DELETE #clear_caches", type: :request do
  # We disable forgery protection by default in  our test environment.
  # We need to enable it to properly test this endpoint.
  around do |example|
    original_forgery_setting = ActionController::Base.allow_forgery_protection
    original_caching_setting = ActionController::Base.perform_caching
    ActionController::Base.allow_forgery_protection = true
    ActionController::Base.perform_caching = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original_forgery_setting
    ActionController::Base.perform_caching = original_caching_setting
  end

  context "anonymous user" do
    let(:id) { 991030207479703811 }
    it "clears the caches" do
      # Go to a catalog page
      get "/catalog/#{id}"

      # Assert that a cache page has been created
      cache_dir = Rails.configuration.action_controller.page_cache_directory
      expected_cache_file = File.join(cache_dir, "catalog", "#{id}.html")
      expect(File.exist?(expected_cache_file)).to be true

      # Now delete the cache
      delete("/clear_caches")
      expect(response.body).to match "Cache has been cleared"

      # Assert that the cached file gets deleted
      expect(File.exist?(expected_cache_file)).to be false
    end
  end
end
