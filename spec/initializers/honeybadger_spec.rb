# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Honeybadger initializer" do
  include ActiveSupport::Testing::TimeHelpers

  def notify(message)
    Honeybadger.notify(StandardError.new(message))
    Honeybadger.flush
  end

  describe "before_notify hook" do
    it "ignores Postgres connection errors on port 5432" do
      notify("port 5432 failed: FATAL: role \"tul_cob\" does not exist")

      expect(Honeybadger::Backend::Test.notifications[:notices]).to be_empty
    end

    it "ignores request errors when no items can fulfill the request" do
      notify("No items can fulfill the submitted request for patron 123")

      expect(Honeybadger::Backend::Test.notifications[:notices]).to be_empty
    end

    it "ignores request errors when activation fails" do
      notify("Failed to activate request due to remote service outage")

      expect(Honeybadger::Backend::Test.notifications[:notices]).to be_empty
    end

    it "ignores errors occurring during the overnight maintenance window" do
      travel_to(Time.utc(2024, 1, 1, 6, 0, 0)) do
        notify("Unexpected error while syncing records")
      end

      expect(Honeybadger::Backend::Test.notifications[:notices]).to be_empty
    end
  end
end
