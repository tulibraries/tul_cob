# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchBuilder , type: :model do
  let(:context) { CatalogController.new }
  let(:params) { ActionController::Parameters.new }
  let(:search_builder) { SearchBuilder.new(context) }
  let(:begins_with_tag) { SearchBuilder::BEGINS_WITH_TAG }

  subject { search_builder }

  describe "#limit_facets" do
    let(:solr_parameters) {
      sp = Blacklight::Solr::Request.new
      # I can't figure out the "right" way to add my test facet fields.
      sp["facet.field"] = [ "foo", "bar", "bizz", "buzz" ]
      sp
    }

    before(:example) do
      allow(search_builder).to receive(:blacklight_params).and_return(params)
      subject.limit_facets(solr_parameters)
    end

    context "the unknown" do
      it "does not affect any facet fields" do
        expect(solr_parameters["facet.field"]).to eq([ "foo", "bar", "bizz", "buzz" ])
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
      sp["qf"] = "foo"
      sp
    }

    before(:example) do
      allow(search_builder).to receive(:blacklight_params).and_return(params)
      subject.tweak_query(solr_parameters)
    end

    context "no overriding query parameter is passed" do
      it "does not override the qf param" do
        expect(solr_parameters["qf"]).to eq("foo")
      end
    end

    context "overriding query parameter is passed" do
      let(:params) { ActionController::Parameters.new(
        qf: "bar"
      ) }

      it "does override the qf param" do
        expect(solr_parameters["qf"]).to eq("bar")
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
      sp["qf"] = "foo"
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

  describe "#process_begins_with" do
    it "can handle nil gracefully" do
      expect(subject.process_begins_with(nil, nil)).to be_nil
      expect(subject.process_begins_with("foo", nil)).to eq("foo")
    end

    it "ignores values if op is not begins_with" do
      expect(subject.process_begins_with("foo", "opbar")).to eq("foo")
    end

    it "adds prefix and quotes to value if op equals begins_with" do
      expect(subject.process_begins_with("foo", "begins_with")).to eq("\"#{begins_with_tag} foo\"")
    end

  end

  describe "#process_is" do
    it "can handle nil case with grace" do
      expect(subject.process_is(nil, nil)).to be_nil
      expect(subject.process_is("foo", nil)).to eq("foo")
    end

    it "ignores values if op is not is" do
      expect(subject.process_is("foo", "opbar")).to eq("foo")
    end

    it "adds quotes to value if op equals is" do
      expect(subject.process_is("foo", "is")).to eq("\"foo\"")
    end

    it "avoids escape hell by ignoring values with quotes" do
      expect(subject.process_is("foo\"bar\"", "is")).to eq("foo\"bar\"")
    end
  end

  describe "#substitute_special_chars" do
    it "can handle nil case with grace" do
      expect(subject.substitute_special_chars(nil, nil)).to be_nil
      expect(subject.substitute_special_chars("foo", nil)).to eq("foo")
    end

    it "substitutes colons from values no matter what op is" do
      expect(subject.substitute_special_chars("foo:bar", nil)).to eq("foo bar")
    end

    it "substitutes all the colons from values" do
      expect(subject.substitute_special_chars("foo:bar:bum", nil)).to eq("foo bar bum")
    end

    it "substitute ? marks" do
      # @see BL-1301 for ref.  Basically Solr treats ? as a special character.
      expect(subject.substitute_special_chars("foo bar?", nil)).to eq("foo bar ")
    end

    it "substitutes empty parens '()' " do
      expect(subject.substitute_special_chars("foo () bar", nil)).to eq("foo   bar")
    end

    it "does not substitutes parens containing values " do
      expect(subject.substitute_special_chars("foo (bar) baz", nil)).to eq("foo (bar) baz")
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
    def proc1(v, _) "#{v} foo" end
    def proc2(v, _) "#{v} bar" end
    def proc3(v, _) "#{v} bum" end
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
      expect(params["q_1"]).to eq("Hello foo bar bum")
      expect(params["q_2"]).to eq("Beautiful foo bar bum")
      expect(params["q_3"]).to eq("World foo bar bum")
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
      let(:params) { { "operator" => { "f_1" => "foo" }, "f_1" => "buzz" } }

      it "does not affect non query values" do
        subject.send(:process_params!, params, [:proc1, :proc2, :proc3])
        expect(params["f_1"]).to eq("buzz")
      end
    end

  end

  describe BentoSearchBuilderBehavior do
    let(:solr_parameters) {
      sp = Blacklight::Solr::Request.new
      sp["facet.field"] = [ "foo", "bar", "bizz", "buzz" ]
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
            unknown_facet_field: "foo",
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
          unknown_facet_field: "foo",
          format: "bar",
          lc_outer_facet: "hat"
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
          unknown_facet_field: "foo",
          format: "bar",
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
  end



end
