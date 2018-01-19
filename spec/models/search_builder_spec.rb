# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchBuilder , type: :model do
  let(:context) { CatalogController.new }
  let(:params) { ActionController::Parameters.new }
  let(:search_builder) { SearchBuilder.new(context) }
  let(:begins_with_tag) { SearchBuilder::BEGINS_WITH_TAG }

  subject { search_builder }

  before(:example) do
    allow(search_builder).to receive(:blacklight_params).and_return(params)
  end

  describe ".escape_colons" do
    let(:solr_parameters) { Blacklight::Solr::Request.new(q: "foo :: bar:buzz") }

    before(:example) do
      subject.escape_colons(solr_parameters)
    end

    context "when not doing an advanced search" do
      it "substitutes all the colons with spaces" do
        expect(solr_parameters["q"]).to eq("foo    bar buzz")
      end
    end

    context "when doing an advanced search" do
      let(:params) { ActionController::Parameters.new(
        search_field: "advanced",
        q_1:  ":",
        q_2: ":foo ::: bar",
      ) }

      it "substitue colons in the addtional query values: q_1, q_2, q_3" do
        expect(solr_parameters["q_1"]).to eq(" ")
        expect(solr_parameters["q_2"]).to eq(" foo     bar")
      end
    end
  end

  describe ".disable_advanced_spellcheck" do
    let(:solr_parameters) { Blacklight::Solr::Request.new(spellcheck: "true") }

    context "when not doing an advanced search" do
      it "does not disable the spellcheck" do
        subject.disable_advanced_spellcheck(solr_parameters)
        expect(solr_parameters["spellcheck"]).to eq("true")
      end
    end

    context "when doing an advanced search" do
      let(:params) { ActionController::Parameters.new(search_field: "advanced") }

      it "disables the spellcheck" do
        subject.disable_advanced_spellcheck(solr_parameters)
        expect(solr_parameters["spellcheck"]).to eq("false")
      end
    end
  end


  describe "#begins_with_search" do
    context "passing empty solr_parameters" do
      it "does nothing" do
        solr_parameters = Blacklight::Solr::Request.new

        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q"]).to be_nil
      end
    end

    context "Passing non advanced query." do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["contains", "contains", "contains"], "q_1" => "Hello") }

      it "does not dereference the key value" do
        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q"]).to eq("_query_:\"{}Hello\"")
      end

      it "does not set a custom solr_parameter for q_1 field." do
        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q_1"]).to be_nil
      end
    end

    context "passing advanced query with :contains precision" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["contains", "contains", "contains"], "q_1" => "Hello", search_field: "advanced") }

      it "dereferences the key value" do
        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q"]).to eq("_query_:\"{ v=$q_1}\"")
      end

      it "sets a custom solr_parameter for q_1 field." do
        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q_1"]).to eq("Hello")
      end
    end

    context "passing advanced query  with :begins_with precision" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["begins_with", "contains", "contains"], "q_1" => "Hello", search_field: "advanced") }

      it "dereferences the key value" do
        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q"]).to eq("_query_:\"{ v=$q_1}\"")
      end

      it "quotes the passed in value." do
        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q_1"]).to eq("\"#{begins_with_tag} Hello\"")
      end
    end

    context "passing advanced subqueries with :begins_with precision" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\" AND _query_:\"{}World\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["begins_with", "contains", "contains"], "q_1" => "Hello", "q_2" => "World", search_field: "advanced") }

      it "dereferences multiple key values" do
        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q"]).to eq("_query_:\"{ v=$q_1}\" AND _query_:\"{ v=$q_2}\"")
      end

      it "quotes the passed if used" do
        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q_1"]).to eq("\"#{begins_with_tag} Hello\"")
        expect(solr_parameters["q_2"]).to eq("World")
      end
    end

    context "passing advanced subqueries where start query is qualified" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "NOT _query_:\"{}Hello\" AND _query_:\"{}World\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["begins_with", "contains", "contains"], "q_1" => "Hello", "q_2" => "World", search_field: "advanced") }

      it "does not drop the first query qualifier" do
        subject.begins_with_search(solr_parameters)
        expect(solr_parameters["q"]).to eq("NOT _query_:\"{ v=$q_1}\" AND _query_:\"{ v=$q_2}\"")
      end
    end

    context "process exact_phrase_search after :begins_with" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["begins_with", "contains", "contains"], "q_1" => "Hello", search_field: "advanced") }

      it "quotes the passed in value." do
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
        allow(search_builder).to receive(:blacklight_params).and_return(params1)
        subject.begins_with_search(solr_parameters)
        allow(search_builder).to receive(:blacklight_params).and_return(params2)
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q_1"]).to eq("Hello")
      end
    end
  end

  describe "#exact_phrase_search" do
    context "passing empty solr_parameters" do
      it "does nothing" do
        solr_parameters = Blacklight::Solr::Request.new

        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q"]).to be_nil
      end
    end

    context "passing non advanced query" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["contains", "contains", "contains"], "q_1" => "Hello") }

      it "does not dereferences the key value" do
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q"]).to eq("_query_:\"{}Hello\"")
      end

      it "does not set a custom solr_parameter for q_1 field." do
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q_1"]).to be_nil
      end
    end

    context "passing advanced query with :contains precision" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["contains", "contains", "contains"], "q_1" => "Hello", search_field: "advanced") }

      it "dereferences the key value" do
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q"]).to eq("_query_:\"{ v=$q_1}\"")
      end

      it "sets a custom solr_parameter for q_1 field." do
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q_1"]).to eq("Hello")
      end
    end

    context "passing advanced query with :is precision" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["is", "contains", "contains"], "q_1" => "Hello", search_field: "advanced") }

      it "dereferences the key value" do
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q"]).to eq("_query_:\"{ v=$q_1}\"")
      end

      it "quotes the passed in value." do
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q_1"]).to eq("\"Hello\"")
      end
    end

    context "passing advanced subqueries with :is precision" do
      let(:solr_parameters) { Blacklight::Solr::Request.new(q: "_query_:\"{}Hello\" AND _query_:\"{}World\"") }
      let(:params) { ActionController::Parameters.new("op_row" => ["is", "contains", "contains"], "q_1" => "Hello", "q_2" => "World", search_field: "advanced") }

      it "dereferences multiple key values" do
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q"]).to eq("_query_:\"{ v=$q_1}\" AND _query_:\"{ v=$q_2}\"")
      end

      it "quotes the passed if used" do
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
        allow(search_builder).to receive(:blacklight_params).and_return(params1)
        subject.begins_with_search(solr_parameters)
        allow(search_builder).to receive(:blacklight_params).and_return(params2)
        subject.exact_phrase_search(solr_parameters)
        expect(solr_parameters["q_1"]).to eq("\"Hello\"")
      end
    end

  end
end
