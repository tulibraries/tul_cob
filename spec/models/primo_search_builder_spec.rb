# frozen_string_literal: true

require "rails_helper"

RSpec.describe Blacklight::PrimoCentral::SearchBuilder , type: :model do
  let(:context) { CatalogController.new }
  let(:params) { ActionController::Parameters.new }
  let(:search_builder) { Blacklight::PrimoCentral::SearchBuilder.new(context) }
  let(:rows) { false }
  let(:start) { false }

  subject { search_builder }

  before(:example) do
    allow(search_builder).to receive(:blacklight_params).and_return(params)
  end

  let(:primo_central_parameters) { Blacklight::PrimoCentral::Request.new }

  describe ".add_query_to_primo_central" do
    before(:example) do
      subject.add_query_to_primo_central(primo_central_parameters)
    end

    context "the unknown" do
      it "has a default query value" do
        expect(primo_central_parameters["query"]["q"]["value"]).to eq("*")
      end
    end

    context "simple search" do
      let(:params) { ActionController::Parameters.new(q: "foo") }

      it "properly sets a query value" do
        expect(primo_central_parameters["query"]["q"]["value"]).to eq("foo")
      end

      it "sets a default query limit" do
        expect(primo_central_parameters["query"]["limit"]).to eq(10)
      end

      it "sets the default offset to zero" do
        expect(primo_central_parameters["query"]["offset"]).to eq(0)
      end

      it "sets a default sort field" do
        expect(primo_central_parameters["query"]["sort"]).to eq("rank")
      end
    end

    context "with sort param override" do
      let(:params) { ActionController::Parameters.new(q: "foo", sort: "bar") }

      it "overrides the default sort field" do
        expect(primo_central_parameters["query"]["sort"]).to eq("bar")
      end
    end

    context "param :id is searched" do
      let(:params) { ActionController::Parameters.new(id: "foo") }

      it "sets query value to quoted :id" do
        expect(primo_central_parameters["query"]["q"]["value"]).to eq("'foo'")
      end
    end
  end

  describe ".process_advanced_search" do
    before(:example) do
      subject.add_query_to_primo_central(primo_central_parameters)
      subject.process_advanced_search(primo_central_parameters)
    end

    context "the unknown" do
      it "does not mess with non adavanced search " do
        expect(primo_central_parameters["query"]["q"]["value"]).to eq("*")
      end
    end

    context "advanced search" do
      let(:params) { ActionController::Parameters.new(q_1: "foo") }

      it "properly sets a query to be a build query" do
        expected = [{ "value" => "foo", "field" => :any, "precision" => nil, "operator" => nil }]
        expect(primo_central_parameters["query"]["q"]["value"]).to eq(expected)
      end
    end

    context "description field is used in advanced setting" do
      let(:params) { ActionController::Parameters.new(q_1: "foo", f_1: "description") }

      it "properly maps description to desc" do
        expected = [{ "value" => "foo", "field" => :desc, "precision" => nil, "operator" => nil }]
        expect(primo_central_parameters["query"]["q"]["value"]).to eq(expected)
      end
    end

    context "empty advanced search" do
      let(:params) { ActionController::Parameters.new(q_1: "") }

      it "shouldn't bother building an empty advanced query" do
        expect(primo_central_parameters["query"]["q"]["value"]).to eq("*")
      end
    end

    context "simple advanced search" do
      let(:params) { ActionController::Parameters.new(q_1: "foo", q_2: "") }

      it "should skip empty advanced queries" do
        expected = [{ "value" => "foo", "field" => :any, "precision" => nil, "operator" => nil }]
        expect(primo_central_parameters["query"]["q"]["value"]).to eq(expected)
      end
    end
  end

  describe ".set_query_field" do
    before(:example) do
      subject.add_query_to_primo_central(primo_central_parameters)
      subject.set_query_field(primo_central_parameters)
    end

    context "search_field not specified" do
      it "sets the default field to search on as :any" do
        expect(primo_central_parameters["query"]["q"]["field"]).to eq(:any)
      end
    end

    context "searh_field is tranformable" do
      let(:params) { ActionController::Parameters.new(search_field: :isbn_t) }

      it "transforms the search field" do
        expect(primo_central_parameters["query"]["q"]["field"]).to eq(:isbn)
      end
    end

    context "search_field is set to advanced" do
      let(:params) { ActionController::Parameters.new(search_field: :advanced) }

      it "advanced transforms to :any" do
        expect(primo_central_parameters["query"]["q"]["field"]).to eq(:any)
      end
    end

    context "search_field is not tranformable" do
      let(:params) { ActionController::Parameters.new(search_field: "foo") }

      it "the field is passed as is" do
        expect(primo_central_parameters["query"]["q"]["field"]).to eq("foo")
      end
    end
  end

  describe ".add_query_facets" do
  end

  describe ".process_date_range_query" do
    before(:example) do
      subject.add_query_to_primo_central(primo_central_parameters)
      subject.set_query_field(primo_central_parameters)
      subject.add_query_facets(primo_central_parameters)
      subject.process_date_range_query(primo_central_parameters)
    end

    context "range not provided" do
      it "adds a default range" do
        expect(primo_central_parameters[:range]).to eq(OpenStruct.new(min: nil, max: nil))
      end

      it "does not add a range facet to the search" do
        expect(primo_central_parameters[:query][:q].include_facets).to be_nil
      end
    end

    context "only one range is provided" do
      let(:params) { ActionController::Parameters.new(
        range:  { creationdate: { begin: "0" } }
      ) }

      it "adds a default range" do
        expect(primo_central_parameters[:range]).to eq(OpenStruct.new(min: "0", max: nil))
      end

      it "does not add a range facet to the search" do
        expect(primo_central_parameters[:query][:q].include_facets).to be_nil
      end
    end

    context "a range limit is empty" do
      let(:params) { ActionController::Parameters.new(
        range:  { creationdate: { begin: "0", end: "" } }
      ) }

      it "adds a default range" do
        expect(primo_central_parameters[:range]).to eq(OpenStruct.new(min: "0", max: ""))
      end

      it "does not add a range facet to the search" do
        expect(primo_central_parameters[:query][:q].include_facets).to be_nil
      end
    end


    context "both min and max range are provided" do
      let(:params) { ActionController::Parameters.new(
        range:  { creationdate: { begin: "0", end: "0" } }
      ) }

      it "adds a default range" do
        expect(primo_central_parameters[:range]).to eq(OpenStruct.new(min: "0", max: "0"))
      end

      it "adds a range facet to the search" do
        facets = primo_central_parameters[:query][:q].include_facets
        expect(facets).to eq("facet_searchcreationdate,exact,[0 TO 0]")
      end
    end
  end

  describe ".previous_and_next_document" do
    before(:example) do
      subject.instance_variable_set(:@rows, 3) if rows
      subject.instance_variable_set(:@start, 5) if start
      subject.add_query_to_primo_central(primo_central_parameters)
      subject.previous_and_next_document(primo_central_parameters)
    end

    context "neither @rows nor @start is set" do
      it "does not affect the limit parameter" do
        expect(primo_central_parameters["query"]["limit"]).to eq(10)
      end

      it "does not affect the offset parameter" do
        expect(primo_central_parameters["query"]["offset"]).to eq(0)
      end
    end

    context "@rows is set" do
      let(:rows) { true }
      it "sets the limit param equal to @rows" do
        expect(primo_central_parameters["query"]["limit"]).to eq(3)
      end
    end

    context "@start is set" do
      let(:start) { true }
      it "it sets the offset param equal to @start" do
        expect(primo_central_parameters["query"]["offset"]).to eq(5)
      end
    end
  end
end
