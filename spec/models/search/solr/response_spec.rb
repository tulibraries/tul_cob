# frozen_string_literal: true

require "rails_helper"

RSpec.describe Search::Solr::Response, type: :model do

  let (:config) { SearchController.blacklight_config }
  let (:response) { Search::Solr::Response.new(facet_counts, {}, { blacklight_config: config }) }
  let (:facet) { { name: "foo", value: "bar", hits: 1 } }


  describe ".merge_facet" do
    before  do
      response.merge_facet(facet)
    end

    context "facet does not already exist" do
      it "adds the facet and appends the new field name and value" do
        expect(response.facet_fields["foo"]).to eq(["bar", 1])
      end
    end

    context "facet exists but field does not exist" do
      let(:facet) { { name: "cat", value: "bar", hits: 1 } }

      it "appends the new field name and value" do
        expect(response.facet_fields["cat"]).to eq(["memory", 3, "card", 2, "bar", 1])
      end
    end

    context "facet exists and field exists" do
      let(:facet) { { name: "cat", value: "memory", hits: 4 } }

      it "appends the new field name and value and aggregations uses new value" do
        expect(response.aggregations["cat"].items.count).to eq(2)
        expect(response.aggregations["cat"].items.first.value).to eq("memory")
        expect(response.aggregations["cat"].items.first.hits).to eq(4)
      end
    end
  end

  def facet_counts
    { "facet_counts" =>
      { "facet_fields" => {
        "cat" => [ "memory", 3, "card", 2 ],
        "manu" => [ "belkin", 2, "canon", 2 ] } } }
  end

end
