# frozen_string_literal: true

require "rails_helper"
require "alma/electronic/business"

RSpec.describe Alma::Electronic::Business do

  describe "#service_id" do
    it "adds 1 to second string and -1 to tenth string" do
      expect(subject.service_id("10111111123")).to eq("11111111113")
    end
  end
end
