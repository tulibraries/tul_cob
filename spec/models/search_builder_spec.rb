# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchBuilder , type: :model do
  let(:context) { CatalogController.new }
  let(:params) { ActionController::Parameters.new }
  let(:search_builder) { SearchBuilder.new(context) }

  subject { search_builder }

  describe "clause limit protections" do
    let(:blacklight_config) do
      Blacklight::Configuration.new.tap do |config|
        config.default_solr_params = {
          qt: "search",
          "facet.field" => ["lc_classification"]
        }

        config.add_search_field("all_fields") do |field|
          field.solr_parameters = {
            qf: "text",
            pf: "title_statement_t^5",
            pf2: "title_t^3"
          }
        end
      end
    end

    let(:context) do
      double(
        "controller",
        blacklight_config: blacklight_config
      )
    end

    it "includes the clause-limit search processors" do
      expect(described_class.default_processor_chain).to include(
        :force_query_parser_for_advanced_search,
        :truncate_overlong_search_query,
        :manage_long_queries_for_clause_limits,
        :normalize_def_type_for_simple_queries
      )
    end

    context "with a very long query" do
      let(:long_query) { Array.new(30, "term").join(" ") }
      let(:params) { { q: long_query, search_field: "all_fields" } }

      subject(:solr_params) do
        described_class
          .new(context)
          .with(params)
          .processed_parameters
      end

      it "truncates and rewrites the query to avoid excessive clauses" do
        q = solr_params[:q] || solr_params["q"]
        def_type = solr_params[:defType] || solr_params["defType"]

        expect(q.split.length).to eq(described_class::MAX_QUERY_TOKENS)
        expect(q).to start_with('"')
        expect(q).to end_with('"')
        expect(def_type).to eq("lucene")
        expect(solr_params).not_to have_key("pf")
        expect(solr_params).not_to have_key("pf2")
        expect(solr_params).not_to have_key("pf3")
      end
    end
  end

  describe "#limit_facets" do
    let(:solr_parameters) {
      sp = Blacklight::Solr::Request.new
      sp["qf"] = "title_t"
      sp
    }



    before(:example) do
      allow(search_builder).to receive(:blacklight_params).and_return(params)
      subject.limit_facets(solr_parameters)
    end

    context "the unknown" do
      it "does not set facet fields" do
        expect(solr_parameters["facet.field"]).to be_nil
      end
    end

    context "catalog index before performing an actual search" do
      let(:params) { ActionController::Parameters.new(
        controller: "catalog",
        action: "index",
      ) }

      it "limits the fields to three selected facets" do
        expect(solr_parameters["facet.field"]).to eq([ "availability_facet", "library_facet", "format" ])
      end
    end

    context "when range limit pings solr" do
      let(:params) { ActionController::Parameters.new(
        controller: "catalog",
        action: "range_limit",
      ) }

      it "limits the facet field to an empty set" do
        expect(solr_parameters["facet.field"]).to eq([])
      end
    end

    context "when on the the advanced search page" do
      let(:params) { ActionController::Parameters.new(
        controller: "catalog",
        action: "range_limit",
      ) }

      it "limits the facet field to an empty set" do
        expect(solr_parameters["facet.field"]).to eq([])
      end
    end

    context "when doing a query_list query" do
      let(:params) { ActionController::Parameters.new(
        controller: "catalog",
        action: "query_list",
      ) }

      it "disables faceting" do
        expect(solr_parameters["facet"]).to eq("off")
      end
    end

    context "when doing a opensearch query" do
      let(:params) { ActionController::Parameters.new(
        controller: "catalog",
        action: "opensearch",
      ) }

      it "disables faceting" do
        expect(solr_parameters["facet"]).to eq("off")
      end
    end
  end

  describe "#tweak_query" do
    let(:solr_parameters) {
      sp = Blacklight::Solr::Request.new
      sp["qf"] = "title_t"
      sp
    }

    before(:example) do
      allow(search_builder).to receive(:blacklight_params).and_return(params)
      subject.tweak_query(solr_parameters)
    end

    context "no overriding query parameter is passed" do
      it "does not override the qf param" do
        expect(solr_parameters["qf"]).to eq("title_t")
      end
    end

    context "overriding query parameter is passed" do
      let(:params) { ActionController::Parameters.new(
        qf: "subject_t"
      ) }

      it "does override the qf param" do
        expect(solr_parameters["qf"]).to eq("subject_t")
      end
    end
  end

  describe "#filter_suppressed" do
    before(:example) do
      allow(search_builder).to receive(:blacklight_params).and_return(params)
      subject.filter_suppressed(solr_parameters)
    end

    context "default" do
      let(:solr_parameters) { Blacklight::Solr::Request.new }

      it "adds suppression to fq" do
        expect(solr_parameters["fq"]).to eq(["-suppress_items_b:true"])
      end
    end
  end

  describe "#filter_id" do
    let(:solr_parameters) { Blacklight::Solr::Request.new }

    before(:example) do
      allow(search_builder).to receive(:blacklight_params).and_return(params)
      subject.filter_id(solr_parameters)
    end

    context "with filter_id param present" do
      let(:params) { ActionController::Parameters.new(
        filter_id: "fizz"
      ) }

      it "adds id suppression to fq" do
        expect(solr_parameters["fq"]).to eq(["-id:fizz"])
      end
    end

    context "without filter_id param present" do
      it "does not add id suppression to f" do
        expect(solr_parameters["fq"]).to be_nil
      end
    end
  end

  describe "#spellcheck" do
    let(:solr_parameters) {
      sp = Blacklight::Solr::Request.new
      sp["qf"] = "title_t"
      sp
    }

    before(:example) do
      allow(search_builder).to receive(:blacklight_params).and_return(params)
      allow(search_builder).to receive(:is_advanced_search?).and_return(is_advanced_search?)

      subject.spellcheck(solr_parameters)
    end

    context "is advanced search" do
      let(:is_advanced_search?)  { true }

      it "disables spellcheck" do
        expect(solr_parameters["spellcheck"]).to eq(false)
      end
    end
  end

  describe "#process_call_number" do
    context "field is not a call number field" do
      it "value stays the same" do
        expect(subject.process_call_number(value: "ML", field: "title_t")).to eq("ML")
      end
    end

    context "field is call_number and op is contains" do
      it "wraps the values with *" do
        expect(subject.process_call_number(value: "ML", field: "call_number", op: "contains")).to eq("{!lucene df=call_number_t allowLeadingWildcard=true}*ml*")
      end

      it "escapes spaces and lowercases" do
        value = "ML 1700 H973o 1996"
        expect(subject.process_call_number(value:, field: "call_number", op: "contains")).to eq("{!lucene df=call_number_t allowLeadingWildcard=true}*ml\\ 1700\\ h973o\\ 1996*")
      end
    end

    context "field is call_number and op is begins_with" do
      it "wraps the values with *" do
        expect(subject.process_call_number(value: "ML", field: "call_number", op: "begins_with")).to eq("{!lucene df=call_number_t allowLeadingWildcard=true}ml*")
      end

      it "escapes spaces and lowercases" do
        value = "ML 1700 H973o 1996"
        expect(subject.process_call_number(value:, field: "call_number", op: "begins_with")).to eq("{!lucene df=call_number_t allowLeadingWildcard=true}ml\\ 1700\\ h973o\\ 1996*")
      end
    end

    context "field is call_number and op is not contains or begins with" do
      it "returns the escaped value" do
        expect(subject.process_call_number(value: "ML", field: "call_number", op: "bar")).to eq("{!lucene df=call_number_t allowLeadingWildcard=true}ml")
      end
    end

  end

  describe "#process_begins_with" do
    it "can handle nil gracefully" do
      expect(subject.process_begins_with(value: nil)).to be_nil
    end

    it "ignores values if op is not begins_with" do
      expect(subject.process_begins_with(value: "ML", op: "opbar")).to eq("ML")
    end

    it "returns value for begins_with when call number handled elsewhere" do
      expect(subject.process_begins_with(value: "ML", op: "begins_with")).to eq("ML")
    end
  end

  describe "#sanitize_query" do
    context "when the value starts and ends with single quotes" do
      it "replaces single quotes with double quotes" do
        expect(subject.sanitize_query(value: "'example'")).to eq('"example"')
      end
    end

    context "when the value starts with a single quote but does not end with one" do
      it "does not modify the value" do
        expect(subject.sanitize_query(value: "'example")).to eq("'example")
      end
    end

    context "when the value ends with a single quote but does not start with one" do
      it "does not modify the value" do
        expect(subject.sanitize_query(value: "example'")).to eq("example'")
      end
    end

    context "when the value contains single quotes in the middle" do
      it "does not modify the value" do
        expect(subject.sanitize_query(value: "exam'ple")).to eq("exam'ple")
      end
    end

    context "when the value does not contain single quotes" do
      it "returns the original value" do
        expect(subject.sanitize_query(value: "example")).to eq("example")
      end
    end

    context "when the value is nil" do
      it "returns nil" do
        expect(subject.sanitize_query(value: nil)).to be_nil
      end
    end

    context "when the value is an empty string" do
      it "returns an empty string" do
        expect(subject.sanitize_query(value: "")).to eq("")
      end
    end
  end

  describe "#process_query" do
    it "can handle nil case with grace" do
      expect(subject.process_query(value: nil, op: nil)).to be_nil
      expect(subject.process_query(value: "ML")).to eq("ML")
    end

    it "ignores values if op is not is" do
      expect(subject.process_query(value: "ML", op: "opbar")).to eq("ML")
    end

    it "adds quotes to value if op equals is" do
      expect(subject.process_query(value: "ML", op: "is")).to eq("\"ML\"")
    end

    it "removes a single quote and then adds quotes to value" do
      expect(subject.process_query(value: "\"bar", op: "is")).to eq("\"bar\"")
    end

    it "avoids escape hell by ignoring values with quotes" do
      expect(subject.process_query(value: "ML\"bar\"", op: "is")).to eq("ML\"bar\"")
    end
  end

  describe "#substitute_special_chars" do
    it "returns nil for nil input" do
      expect(subject.substitute_special_chars(value: nil, op: nil)).to be_nil
    end

    it "keeps values without special chars" do
      expect(subject.substitute_special_chars(value: "ML128.B26F6 1988", op: nil)).to eq("ML128.B26F6 1988")
    end

    it "replaces question marks and colons with spaces" do
      expect(subject.substitute_special_chars(value: "ML?128:A4", op: nil)).to eq("ML 128 A4")
    end

    it "does not alter call number fielded queries" do
      value = "call_number_t:ml128.a4\\ t48\\ 1960*"
      expect(subject.substitute_special_chars(field: "call_number", value:, op: nil)).to eq(value)
    end

    it "does not alter local param queries" do
      value = "{!lucene df=call_number_t}ml128.a4"
      expect(subject.substitute_special_chars(field: "call_number", value:, op: nil)).to eq(value)
    end
  end

  describe "#blacklight_params" do


    it "gets tagged as being processed" do
      expect(subject.blacklight_params["processed"]).to be
    end

    it "is idempotent" do
      subject.blacklight_params
      subject.blacklight_params
      subject.blacklight_params
      subject.blacklight_params
      expect(subject.blacklight_params).to eq("processed" => true, "q" => nil)
    end
  end

  class SearchBuilder < Blacklight::SearchBuilder
    def proc1(value:, **rest) "#{value} first" end
    def proc2(value:, **rest) "#{value} second" end
    def proc3(value:, **rest) "#{value} third" end
  end

  describe "#process_params!" do
    let(:params) { ActionController::Parameters.new(
      "operator" => { "q_1" => "bizz", "q_2" => "buzz", "q_3" => "bazz" },
      "f_1" => "all_fields", "q_1" => "Hello",
      "f_2" => "all_fields", "q_2" => "Beautiful",
      "f_3" => "all_fields", "q_3" => "World",
      search_field: "advanced") }

    it "tags the passed in parameters as processed" do
      subject.send(:process_params!, params, [])
      expect(params["processed"]).to be true
    end

    it "folds the procedures over the parameter values" do
      subject.send(:process_params!, params, [:proc1, :proc2, :proc3])
      expect(params["q_1"]).to eq("Hello first second third")
      expect(params["q_2"]).to eq("Beautiful first second third")
      expect(params["q_3"]).to eq("World first second third")
    end

    it "handles the nil params case gracefully" do
      params = subject.send(:process_params!, nil, [:proc1, :proc2, :proc3])
      expect(params["processed"]).to be true
    end

    it "handles the nil procedures gracefully" do
      subject.send(:process_params!, params, nil)
      expect(params["processed"]).to be true
    end

    context "operator has non query keys" do
      let(:params) { { "operator" => { "f_1" => "title_t" }, "f_1" => "buzz" } }

      it "does not affect non query values" do
        subject.send(:process_params!, params, [:proc1, :proc2, :proc3])
        expect(params["f_1"]).to eq("buzz")
      end
    end

  end

  describe BentoSearchBuilderBehavior do
    let(:solr_parameters) {
      sp = Blacklight::Solr::Request.new
      sp["facet.field"] = [ "availability_facet", "library_facet", "format", "language_facet" ]
      sp["facets"] = true
      sp["rows"] = 10
      sp["stats"] = true
      sp
    }

    describe "#remove_facets" do
      before(:example) do
        subject.remove_facets(solr_parameters)
      end

      it "sets facets param to false" do
        expect(solr_parameters["facets"]).to be(false)
      end

      it "removes the facet.field params" do
        expect(solr_parameters["facet.field"]).to be_nil
      end

      it "sets stats to false" do
        expect(solr_parameters["stats"]).to be(false)
      end

      it "does not touch rows" do
        expect(solr_parameters["rows"]).to eq(10)
      end
    end

    describe "#format_facet_only" do
      before(:example) do
        subject.format_facet_only(solr_parameters)
      end

      it "sets the facet.field param to format" do
        expect(solr_parameters["facet.field"]).to eq("format")
      end

      it "sets the facets param to true" do
        expect(solr_parameters["facets"]).to be(true)
      end
    end

  end

  describe "#add_facet_fq_to_solr" do
    it "converts a String fq into an Array" do
      solr_parameters = { fq: "a string" }

      subject.add_facet_fq_to_solr(solr_parameters)

      expect(solr_parameters[:fq]).to be_a_kind_of Array
    end

    context "unknown facet, basic facet, and pivot facet" do
      let(:solr_parameters) {
        solr_parameters = Blacklight::Solr::Request.new
        params = ActionController::Parameters.new(
          f: {
            unknown_facet_field: "unknown_field",
            format: "bar",
            lc_outer_facet: "hat"
          })
        subject.with(params).add_facet_fq_to_solr(solr_parameters)
        solr_parameters
      }

      it "does not add unkown facets to solr_parameters" do
        expect(solr_parameters[:fq] - ["{!term f=format}bar", "{!term f=lc_outer_facet}hat"]).to be_empty
      end

      it "does add the other two" do
        expect(solr_parameters[:fq].size).to eq 2
      end
    end
  end

  describe "range queries" do
    it "converts 'range' object to correct solr range fields" do
      params = ActionController::Parameters.new(
        f: {
          unknown_facet_field: "unknown_field",
          format: "Book",
          lc_outer_facet: "Class A"
        },
        range: {
          lc_classification: {
            begin: "A",
            end: "K"
          },
          pub_date_sort: {
            begin: "1900",
            end: "1950"
          }
        })
      subject.with(params)
      expect(subject.to_h["fq"]).to include("pub_date_sort: [1900 TO 1950]")
      expect(subject.to_h["fq"]).to include("lc_call_number_sort: [Zaaaaaaaaa TO Zkaaaaaaaa]")
    end

    it "skips when empty lc classification range" do
      params = ActionController::Parameters.new(
        f: {
          unknown_facet_field: "unknown_field",
          format: "Book",
          lc_outer_facet: ""
        },
        range: {
          lc_classification: {
            begin: "",
            end: ""
          },
          pub_date_sort: {
            begin: "1900",
            end: "1950"
          }
        })
      subject.with(params)
      has_lc_call_number_sort_field = subject.to_h["fq"].any? { |f| f.match(/lc_call_number_sort/) }
      expect(has_lc_call_number_sort_field).to be(false)
    end

    it "removes lc_classification from solr_params[facet.field]" do
      subject.with({})
      expect(subject["facet.field"]).not_to include("lc_classification")
    end

    it "does not generate an invalid lc_call_number_sort range when begin converts to blank" do
      allow(LcSolrSortable).to receive(:convert).and_return("")

      params = ActionController::Parameters.new(
        range: {
          lc_classification: {
            begin: "INVALID",
            end: "K"
          }
        }
      )

      subject.with(params)
      fq = subject.to_h["fq"].join(" ")

      expect(fq).not_to match(/\[\s+TO/)
      expect(fq).not_to match(/lc_call_number_sort:\s*\[\s+TO\s*\*\]/)
    end

    it "skips lc_call_number_sort when both range values convert to blank" do
      allow(LcSolrSortable).to receive(:convert).and_return("")

      params = ActionController::Parameters.new(
        range: {
          lc_classification: {
            begin: "INVALID",
            end: "INVALID"
          }
        }
      )

      subject.with(params)

      has_lc = subject.to_h["fq"].any? { |f| f.include?("lc_call_number_sort") }
      expect(has_lc).to be(false)
    end
  end
end
