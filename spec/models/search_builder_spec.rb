# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchBuilder , type: :model do
  let(:context) { CatalogController.new }
  let(:params) { ActionController::Parameters.new }
  let(:search_builder) { SearchBuilder.new(context) }
  let(:begins_with_tag) { SearchBuilder::BEGINS_WITH_TAG }

  subject { search_builder }

  describe "#limit_facets" do
    before(:example) do
      allow(search_builder).to receive(:blacklight_params).and_return(params)
    end

    let(:solr_parameters) {
      sp = Blacklight::Solr::Request.new
      # I can't figure out the "right" way to add my test facet fields.
      sp["facet.field"] = [ "foo", "bar", "bizz", "buzz" ]
      sp
    }

    before(:example) do
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

  describe "#substitute_colons" do
    it "can handle nil case with grace" do
      expect(subject.substitute_colons(nil, nil)).to be_nil
      expect(subject.substitute_colons("foo", nil)).to eq("foo")
    end

    it "substitutes colons from values no matter what op is" do
      expect(subject.substitute_colons("foo:bar", nil)).to eq("foo bar")
    end

    it "substitutes all the colons from values" do
      expect(subject.substitute_colons("foo:bar:bum", nil)).to eq("foo bar bum")
    end
  end

  describe "#blacklight_params" do
    it "gets tagged as being processed" do
      expect(subject.blacklight_params).to eq("processed" => true)
    end

    it "is idempotent" do
      subject.blacklight_params
      subject.blacklight_params
      subject.blacklight_params
      subject.blacklight_params
      expect(subject.blacklight_params).to eq("processed" => true)
    end
  end

  class SearchBuilder < Blacklight::SearchBuilder
    def proc1(v, _) "#{v} foo" end
    def proc2(v, _) "#{v} bar" end
    def proc3(v, _) "#{v} bum" end
  end

  describe "#process_params!" do
    let(:params) { ActionController::Parameters.new(
      "op_row" => ["bizz", "buzz", "bazz"],
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
  end

  describe "#params_field_ops" do
    it "handles the nil params case gracefully" do
      expect(subject.send(:params_field_ops, nil)).to eq([])
    end

    it "handles the empty params case gracefully" do
      expect(subject.send(:params_field_ops, {})).to eq([])
    end

    it "handles a typical advanced search params as expected" do
      params = ActionController::Parameters.new(
        "op_row" => ["bizz", "buzz", "bazz"],
        "f_1" => "all_fields", "q_1" => "Hello",
        "f_2" => "all_fields", "q_2" => "Beautiful",
        "f_3" => "all_fields", "q_3" => "World",
        search_field: "advanced")

      expect(subject.send(:params_field_ops, params)).to eq([
        ["bizz", ["q_1", "Hello"]],
        ["buzz", ["q_2", "Beautiful"]],
        ["bazz", ["q_3", "World"]]])
    end

    it "handles a typical regular search params as expected" do
      params = ActionController::Parameters.new(
        "field" => "all_fields", "q" => "Hello")

      expect(subject.send(:params_field_ops, params)).to eq([
        ["default", ["q", "Hello"]]])
    end

  end
end
