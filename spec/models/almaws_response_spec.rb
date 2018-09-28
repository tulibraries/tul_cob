# frozen_string_literal: true

require "rails_helper"

RSpec.describe Blacklight::Alma::Response, type: :model  do
  let (:json) { { bib: [], total_record_count: 101 }.to_json }
  let (:raw_response) { OpenStruct.new(body: json) }
  let (:bib_items) { Alma::BibItemSet.new(raw_response) }
  let (:response) { Blacklight::Alma::Response.new(bib_items) }

  describe "#limit_value" do
    it "has a default limit value" do
      expect(response.limit_value).to eq(100)
    end
  end

  describe "#total_count" do
    it "parses the total count from the value" do
      expect(response.total_count).to eq(101)
    end
  end

  describe "#start/offset_value" do
    it "has a default value" do
      expect(response.start).to eq(0)
    end

    context "is on page 3" do
      let (:response) { Blacklight::Alma::Response.new(bib_items, page: 3) }
      it "returns an offset based on the page we are on" do
        expect(response.start).to eq(200)
      end
    end
  end

  describe "params" do
    it "has a default value" do
      expect(response.params).to eq("offset" => 0, "limit" => 100)
    end

    context "params are passed in" do
      let (:response) { Blacklight::Alma::Response.new(bib_items, page: 3) }
      it "returns the initialization params" do
        expect(response.params).to eq(page: 3)
      end
    end
  end

  describe "rows" do
    it "returns the number of bib items per initialization" do
      expect(response.rows).to eq(0)
    end
  end
end
