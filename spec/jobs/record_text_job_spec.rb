# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecordTextJob, type: :job do
  describe "#perform_later" do
    it "enqueues a text to send later" do
      ActiveJob::Base.queue_adapter = :test
      expect {
        RecordTextJob.perform_later("text")
      }.to have_enqueued_job
    end
  end
end
