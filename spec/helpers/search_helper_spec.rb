# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchHelper, type: :helper do
  before(:each) do
    BentoSearch.register_engine("one") do |conf|
      conf.engine = "BentoSearch::BlacklightEngine"
    end

    BentoSearch.register_engine("two") do |conf|
      conf.engine = "BentoSearch::BlacklightEngine"
      conf.for_display do |display|
        display.name = "Foo"
      end
    end
  end

  after(:each) do
    BentoSearch.reset_engine_registrations!
  end

  describe "#bento_titleize" do
    context "engine display name not defined" do
      it "titalizes using search engine id" do
        expect(bento_titleize("one")).to match("One")
      end
    end

    context "engine display name is defined" do
      it "titalizes using defined name" do
        expect(bento_titleize("two")).to match("Foo")
      end
    end
  end
end
