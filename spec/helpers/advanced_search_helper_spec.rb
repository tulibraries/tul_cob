# frozen_string_literal: true

require "rails_helper"

RSpec.describe BlacklightAdvancedSearch::RenderConstraintsOverride, type: :helper do
  describe "#guided_search"
   do
     example "empty search fields" do
       expect(helper.guided_search).to be_empty
     end
   end

   example "one search field" do
      params = ActionController::Parameters.new(
        f1: "all_fields",
        search_field: "advanced",
        q1: "james"
      )
      expect(helper.guided_search(params).count).to eq(1)
    end

    example "two search fields" do
      params = ActionController::Parameters.new(
        f1: "all_fields",
        search_field: "advanced",
        q1: "james",
        f2: "all_fields",
        q2: "james",
        op2: "OR"
      )
      expect(helper.guided_search(params).count).to eq(2)
    end

  describe ".op_row_default" do
    example "default" do
      expect(helper.op_row_default(2)).to eq("contains")
    end

    # REF BL-334
    example "two consecutive searches" do
      params = ActionController::Parameters.new(
        q_1: "james",
        q_2: "john",
        q_3: "david",
        op_row: [ "fizz", "fizz", "fizz", "foo", "bar", "bum" ]
      )
      allow(helper).to receive(:params).and_return(params)

      expect(helper.op_row_default(2)).to eq("bar")
    end
  end

end
