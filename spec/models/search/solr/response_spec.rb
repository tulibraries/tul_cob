# frozen_string_literal: true

require "rails_helper"

RSpec.describe Search::Solr::Response, type: :model do

  describe ".merge_facet" do
    let(:config) { Blacklight::Configuration.new }
    let(:response) { Search::Solr::Response.new(facet_counts, {}, { blacklight_config: config }) }
    let(:facet) { { name: "foo", value: "bar", hits: 1 } }

    before(:each)  do
      response.merge_facet(facet)
    end

    context "facet does not already exist" do
      it "adds the facet and appends the new field name and value" do
        expect(response.facet_fields["foo"]).to eq(["bar", 1])
      end
    end

    context "facet exists but field does not exist" do
      let(:facet) { { name: "cat", value: "bar", hits: 1 } }

      it "merges the new field name and sorts by value asc" do
        expect(response.facet_fields["cat"]).to eq(["bar", 1, "card", 2, "memory", 3])
      end
    end

    context "facet exists and field exists" do
      let(:facet) { { name: "cat", value: "memory", hits: 4 } }

      it "merges the new field overriding the old value" do
        expect(response.facet_fields["cat"]).to eq(["card", 2, "memory", 4])
      end
    end

    context "when a sorting procedure is provided" do
      let(:facet) { { name: "cat", value: "bar", hits: 1 } }
      let(:config) {
        bc = Blacklight::Configuration.new
        bc.add_facet_field "cat", sort_proc: -> (f) { (_, h) = f; -h }
        bc
      }

      it "uses the defining sorting proc to do the sorting" do
        expect(response.facet_fields["cat"]).to eq(["memory", 3, "card", 2, "bar", 1])
      end
    end

    context "mutiple merges on same field" do
      it "uses the last merged values"  do
        response.merge_facet(name: "cat", value: "bar", hits: 2)
        response.merge_facet(name: "cat", value: "bar", hits: 3)
        response.merge_facet(name: "cat", value: "bar", hits: 4)

        expect(response.facet_fields["cat"]).to eq(["bar", 4, "card", 2, "memory", 3])
      end
    end

    def facet_counts
      { "facet_counts" => { "facet_fields" => { "cat" => [ "memory", 3, "card", 2 ] } } }
    end
  end
end
