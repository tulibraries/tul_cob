# frozen_string_literal: true

require "rails_helper"

RSpec.describe Blacklight::PrimoCentral::SearchBuilder , type: :model do
  let(:context) { CatalogController.new }
  let(:params) { ActionController::Parameters.new }
  let(:search_builder) { Blacklight::PrimoCentral::SearchBuilder.new(context) }

  subject { search_builder }

  before(:example) do
    allow(search_builder).to receive(:blacklight_params).and_return(params)
  end

  describe ".add_query_to_primo_central" do
    let(:primo_central_parameters) { Blacklight::PrimoCentral::Request.new }

    before(:example) do
      subject.add_query_to_primo_central(primo_central_parameters)
    end

    context "the unknown" do
      it "has a default query" do
        expect(primo_central_parameters["query"]).to eq(
          "q" => { "field" => :any, "value" => nil }
        )
      end
    end

    context "simple search" do
      let(:params) { ActionController::Parameters.new(q: "foo") }

      it "properly sets a query value" do
        expect(primo_central_parameters["query"]["q"]["value"]).to eq("foo")
      end

      it "sets a default field value" do
        expect(primo_central_parameters["query"]["q"]["field"]).to eq(:any)
      end

      it "sets a default query limit" do
        expect(primo_central_parameters["query"]["limit"]).to eq(10)
      end

      it "sets the default offset to zero" do
        expect(primo_central_parameters["query"]["offset"]).to eq(0)
      end
    end
  end

  describe ".add_query_facets" do
  end
end
