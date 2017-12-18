# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchBuilder , type: :model do
  let(:context) { CatalogController.new }
  let(:search_builder) { SearchBuilder.new(context) }
  let(:begins_with_tag) { SearchBuilder::BEGINS_WITH_TAG }

  subject { search_builder }

  describe "#begins_with_search" do
    context "passing empty solr_parameters" do
      it "does nothing" do
        solr_parameters = Blacklight::Solr::Request.new
        allow(context).to receive(:params).and_return({})

        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q"]).to be_nil
      end
    end

    context "Passing non advanced query." do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["contains", "contains", "contains"], "q_1" => "Hello") }

      it "does not dereference the key value" do
        allow(context).to receive(:params).and_return(params)
        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q"]).to eq("_query_:\"{}Hello\"")
      end

      it "does not set a custom solr_parameter for q_1 field." do
        allow(context).to receive(:params).and_return(params)
        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q_1"]).to be_nil
      end
    end

    context "passing advanced query with :contains precision" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["contains", "contains", "contains"], "q_1" => "Hello", search_field: "advanced") }

      it "dereferences the key value" do
        allow(context).to receive(:params).and_return(params)
        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q"]).to eq("_query_:\"{ v=$q_1}\" ")
      end

      it "sets a custom solr_parameter for q_1 field." do
        allow(context).to receive(:params).and_return(params)
        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q_1"]).to eq("Hello")
      end
    end

    context "passing advanced query  with :begins_with precision" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["begins_with", "contains", "contains"], "q_1" => "Hello", search_field: "advanced") }

      it "dereferences the key value" do
        allow(context).to receive(:params).and_return(params)
        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q"]).to eq("_query_:\"{ v=$q_1}\" ")
      end

      it "quotes the passed in value." do
        allow(context).to receive(:params).and_return(params)
        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q_1"]).to eq("\"#{begins_with_tag} Hello\"")
      end
    end

    context "passing advanced subqueries with :begins_with precision" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\" AND _query_:\"{}World\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["begins_with", "contains", "contains"], "q_1" => "Hello", "q_2" => "World", search_field: "advanced") }

      it "dereferences multiple key values" do
        allow(context).to receive(:params).and_return(params)
        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q"]).to eq("_query_:\"{ v=$q_1}\" AND _query_:\"{ v=$q_2}\" ")
      end

      it "quotes the passed if used" do
        allow(context).to receive(:params).and_return(params)
        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q_1"]).to eq("\"#{begins_with_tag} Hello\"")
        expect(solr_parameters["q_2"]).to eq("World")
      end
    end

    context "process exact_phrase_search after :begins_with" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["begins_with", "contains", "contains"], "q_1" => "Hello", search_field: "advanced") }

      it "quotes the passed in value." do
        allow(context).to receive(:params).and_return(params)
        subject.begins_with_search(solr_parameters)
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q_1"]).to eq("\"#{begins_with_tag} Hello\"")
      end
    end

    context "process contains after :begins_with" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\"") }
      let(:params1) { ActionController::Parameters.new("op_row" => ["begins_with", "contains", "contains"], "q_1" => "Hello", search_field: "advanced") }
      let(:params2) { ActionController::Parameters.new("op_row" => ["contains", "contains", "contains"], "q_1" => "Hello", search_field: "advanced") }

      it "does not quote the value." do
        allow(context).to receive(:params).and_return(params1)
        subject.begins_with_search(solr_parameters)
        allow(context).to receive(:params).and_return(params2)
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q_1"]).to eq("Hello")
      end
    end
  end

  describe "#exact_phrase_search" do
    context "passing empty solr_parameters" do
      it "does nothing" do
        solr_parameters = Blacklight::Solr::Request.new
        allow(context).to receive(:params).and_return({})

        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q"]).to be_nil
      end
    end

    context "passing non advanced query" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["contains", "contains", "contains"], "q_1" => "Hello") }

      it "does not dereferences the key value" do
        allow(context).to receive(:params).and_return(params)
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q"]).to eq("_query_:\"{}Hello\"")
      end

      it "does not set a custom solr_parameter for q_1 field." do
        allow(context).to receive(:params).and_return(params)
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q_1"]).to be_nil
      end
    end

    context "passing advanced query with :contains precision" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["contains", "contains", "contains"], "q_1" => "Hello", search_field: "advanced") }

      it "dereferences the key value" do
        allow(context).to receive(:params).and_return(params)
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q"]).to eq("_query_:\"{ v=$q_1}\" ")
      end

      it "sets a custom solr_parameter for q_1 field." do
        allow(context).to receive(:params).and_return(params)
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q_1"]).to eq("Hello")
      end
    end

    context "passing advanced query with :is precision" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["is", "contains", "contains"], "q_1" => "Hello", search_field: "advanced") }

      it "dereferences the key value" do
        allow(context).to receive(:params).and_return(params)
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q"]).to eq("_query_:\"{ v=$q_1}\" ")
      end

      it "quotes the passed in value." do
        allow(context).to receive(:params).and_return(params)
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q_1"]).to eq("\"Hello\"")
      end
    end

    context "passing advanced subqueries with :is precision" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\" AND _query_:\"{}World\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["is", "contains", "contains"], "q_1" => "Hello", "q_2" => "World", search_field: "advanced") }

      it "dereferences multiple key values" do
        allow(context).to receive(:params).and_return(params)
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q"]).to eq("_query_:\"{ v=$q_1}\" AND _query_:\"{ v=$q_2}\" ")
      end

      it "quotes the passed if used" do
        allow(context).to receive(:params).and_return(params)
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q_1"]).to eq("\"Hello\"")
        expect(solr_parameters["q_2"]).to eq("World")
      end
    end

    context "process exact_phrase_search with :is after begins_with_search with :begins_with" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\"") }
      let(:params1) { ActionController::Parameters.new("op_row" => ["begins_with", "contains", "contains"], "q_1" => "Hello", search_field: "advanced") }
      let(:params2) { ActionController::Parameters.new("op_row" => ["is", "contains", "contains"], "q_1" => "Hello", search_field: "advanced") }

      it "quotes the passed in value." do
        allow(context).to receive(:params).and_return(params1)
        subject.begins_with_search(solr_parameters)
        allow(context).to receive(:params).and_return(params2)
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q_1"]).to eq("\"Hello\"")
      end
    end

  end
end
