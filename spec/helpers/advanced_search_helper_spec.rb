# frozen_string_literal: true

require "rails_helper"
module BlacklightAdvancedSearch
  module RenderConstraintsOverride
    def search_field_def_for_key(key)
      { label: "All fields" }
    end
  end
end

RSpec.describe BlacklightAdvancedSearch::RenderConstraintsOverride, type: :helper do
  describe "#guided_search" do

    example "empty search fields" do
      expect(helper.guided_search.empty?).to be(true)
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

    it "can handle more than the number of fields defined (current is 3)" do
      params = ActionController::Parameters.new(
        f1: "all_fields",
        search_field: "advanced",
        q1: "james",
        f2: "all_fields",
        q2: "john",
        op2: "OR",
        f3: "all_fields",
        q3: "david",
        op3: "OR",
        f4: "all_fields",
        q4: "summer",
        op4: "OR"
      )
      expect(helper.guided_search(params).count).to eq(4)
    end
  end
end
