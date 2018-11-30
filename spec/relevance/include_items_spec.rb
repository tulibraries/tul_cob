# frozen_string_literal: true

require "rails_helper"

RSpec.describe "include_items().within_the_first().before()" do
  context "with include_items only" do
    it "checks for included items" do
      expect(["a", "b", "c", "d", "e"]).to include_items(["c", "b"])
    end

    it "fails for excluded items" do
      expect(["a", "b", "c", "d", "e"]).not_to include_items(["f", "b"])
    end
  end

  context "with include_items and within_the_first" do
    it "checks included items are within index" do
      expect(["a", "b", "c", "d", "e"]).to include_items(["c", "b"])
        .within_the_first(3)
    end

    it "fails when not within index" do
      expect(["a", "b", "c", "d", "e"]).not_to include_items(["c", "b"])
        .within_the_first(2)
    end
  end

  context "with include_items and before" do
    it "works with positive assertions" do
      expect(["a", "b", "c", "d", "e"]).to include_items(["c", "b"])
        .before(["e", "d"])
    end

    it "works with negative assertions" do
      expect(["c", "b", "a", "d", "e"]).not_to include_items(["f", "d"])
        .before(["c", "b"])
    end
  end

  context "with include_items, within_the_first and before" do
    it "passes when all are true" do
      expect(["a", "b", "c", "d", "e"]).to include_items(["c", "b"])
        .within_the_first(3)
        .before(["e", "d"])
    end

    it "fails when any is false" do
      expect(["a", "b", "c", "d", "e"]).not_to include_items(["f", "b"])
        .within_the_first(3)
        .before(["e", "d"])

      expect(["a", "b", "c", "d", "e"]).not_to include_items(["f", "b"])
        .within_the_first(2)
        .before(["e", "d"])

      expect(["a", "b", "c", "d", "e"]).not_to include_items(["f", "b"])
        .within_the_first(2)
        .before(["f", "d"])
    end
  end
end
