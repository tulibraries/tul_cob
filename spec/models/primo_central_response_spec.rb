# frozen_string_literal: true

require "rails_helper"

RSpec.describe Blacklight::PrimoCentral::Response, type: :model do

  let (:blacklight_config) { nil }
  let (:response) { Blacklight::PrimoCentral::Response.new(
    {}, {}, { blacklight_config: blacklight_config }
  )}

  describe ".get_rafacets and no range" do
    context "Empty response" do
      let(:stats) { response.get_range_stats([]) }

      it "provides default empty stats" do
        expect(stats).to eq(stats_fields: {})
      end
    end

    context "Facet response but no range facet field set" do
      facets = [{ "name" => "creationdate", "values" => [] }]
      let(:stats) { response.get_range_stats(facets) }
      let(:blacklight_config) { OpenStruct.new(facet_fields: {}) }

      it "provides default empty stats" do
        expect(stats).to eq(stats_fields: {})
      end
    end

    context "Facet response with empty range and facet field set" do
      facets = [{ "name" => "creationdate", "values" => [] }]
      let(:stats) { response.get_range_stats(facets) }
      let(:facet_config) { OpenStruct.new(range: true) }
      let(:blacklight_config) {
        OpenStruct.new(facet_fields: { "creationdate" => facet_config })
      }

      it "provides default empty stats" do
        expect(stats).to eq(stats_fields: { "creationdate" => { min: 0, max: 0, missing: 0, data: [ { from: 0, to: 1, count: 0 } ] } })
      end
    end

    context "Facet response with range and facet field set" do
      facets = [{
        "name" => "creationdate",
        "values" => [
          { "value" => "1973", "count" => 45 },
          { "value" => "2012", "count" => 6 },
        ]
      }]
      let(:stats) { response.get_range_stats(facets) }
      let(:facet_config) { OpenStruct.new(range: true) }
      let(:blacklight_config) {
        OpenStruct.new(facet_fields: { "creationdate" => facet_config })
      }

      it "provides default empty stats" do
        expected = { "creationdate" => {
          min: 1973,
          max: 2012,
          missing: 0,
          data: response.facet_segments("creationdate", 1973, 2012, [
            { value: 1973, count: 45 },
            { value: 2012, count: 6 },
          ]) }
        }
        expect(stats).to eq(stats_fields: expected)
      end
    end
  end

  describe ".facet_segments" do
    let (:data) { [
      { value: 1980, count: 1 },
      { value: 1981, count: 1 },
      { value: 1982, count: 1 },
      { value: 1983, count: 1 },
      { value: 1984, count: 1 },
      { value: 1985, count: 1 },
      { value: 1986, count: 1 },
      { value: 1987, count: 1 },
      { value: 1988, count: 1 },
      { value: 1989, count: 1 },
    ] }

    let(:facet_config) { OpenStruct.new(range: true) }
    let(:blacklight_config) {
      OpenStruct.new(facet_fields: { "creationdate" => facet_config })
    }

    context "segments on outside left of data range" do
      it "all segments have zero counts" do
        actual_segments = response.facet_segments("creationdate", 0, 4, data)
        expected_segments = [
          { from: 0, to: 1, count: 0 },
          { from: 1, to: 2, count: 0 },
          { from: 2, to: 3, count: 0 },
          { from: 3, to: 4, count: 0 },
          { from: 4, to: 5, count: 0 },
        ]
        expect(actual_segments).to eq(expected_segments)
      end
    end

    context "segments on outside right of data range" do
      it "all segments have zero counts" do
        actual_segments = response.facet_segments("creationdate", 1990, 1994, data)
        expected_segments = [
          { from: 1990, to: 1991, count: 0 },
          { from: 1991, to: 1992, count: 0 },
          { from: 1992, to: 1993, count: 0 },
          { from: 1993, to: 1994, count: 0 },
          { from: 1994, to: 1995, count: 0 },
        ]
        expect(actual_segments).to eq(expected_segments)
      end
    end

    context "segments inside subset of data range" do
      it "all segments have correct count" do
        actual_segments = response.facet_segments("creationdate", 1980, 1984, data)
        expected_segments = [
          { from: 1980, to: 1981, count: 1 },
          { from: 1981, to: 1982, count: 1 },
          { from: 1982, to: 1983, count: 1 },
          { from: 1983, to: 1984, count: 1 },
          { from: 1984, to: 1985, count: 1 },
        ]
        expect(actual_segments).to eq(expected_segments)
      end
    end

    context "segments overlaps data range on both sides" do
      it "all segments have correct count" do
        actual_segments = response.facet_segments("creationdate", 1900, 2000, data)
        expected_segments = [
          { from: 1900, to: 1910, count: 0 },
          { from: 1910, to: 1920, count: 0 },
          { from: 1920, to: 1930, count: 0 },
          { from: 1930, to: 1940, count: 0 },
          { from: 1940, to: 1950, count: 0 },
          { from: 1950, to: 1960, count: 0 },
          { from: 1960, to: 1970, count: 0 },
          { from: 1970, to: 1980, count: 0 },
          { from: 1980, to: 1990, count: 10 },
          { from: 1990, to: 2000, count: 0 },
          { from: 2000, to: 2001, count: 0 }
        ]
        expect(actual_segments).to eq(expected_segments)
      end
    end
  end

end
