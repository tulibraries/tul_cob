# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecordEmailJob, type: :job do
  describe "#perform_later" do
    it "enqueues an email to send later" do
      ActiveJob::Base.queue_adapter = :test
      expect {
        RecordEmailJob.perform_later("email")
      }.to have_enqueued_job
    end
  end
end
