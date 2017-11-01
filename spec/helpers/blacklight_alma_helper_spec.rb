# frozen_string_literal: true

require "rails_helper"

# Specs in this file have access to a helper object that includes
# the BlacklightAlmaHelper. For example:
#
# describe BlacklightAlmaHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe BlacklightAlmaHelper, type: :helper do
  describe "#alma_service_type_for_fulfillment_url" do
    example "An online file is available" do
      doc = { "availability_facet" => ["Online"] }
      actual = helper.alma_service_type_for_fulfillment_url doc
      expect(actual).to be("viewit")
    end

    example "An online file is not available" do
      doc = { "availability_facet" => [] }
      actual = helper.alma_service_type_for_fulfillment_url doc
      expect(actual).to be("getit")
    end

    example "Something has gone terribly wrong" do
      doc = nil
      actual = helper.alma_service_type_for_fulfillment_url doc
      expect(actual).to be("getit")
    end
  end
end
