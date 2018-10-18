# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersHelper, type: :helper do
  describe "#make_date" do
    it "returns a date in the correct timezone" do
      iso8601_dt = "2018-10-16T02:00:00Z"
      expect(make_date(iso8601_dt)).to eql "10/15/2018"
    end
  end
end
