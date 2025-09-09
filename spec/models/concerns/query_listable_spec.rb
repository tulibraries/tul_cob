# frozen_string_literal: true

require "rails_helper"

RSpec.describe QueryListable, type: :model do

  subject { document.extend(QueryListable) }

  describe "#query_list_footer_value" do
    let(:value) { subject.query_list_footer_value(footer_field) }

    context "field not present in documeent" do
      let(:footer_field) { "some_rando_field" }
      let(:document) { SolrDocument.new({}) }

      it "returns nil"  do
        expect(value).to be_nil
      end
    end

    context "field present in doc" do
      let(:footer_field) { "some_rando_field" }
      let(:document) { SolrDocument.new({ "some_rando_field" => ["foo"] }) }

      it "returns first value by default"  do
        expect(value).to eq("foo")
      end
    end

    context "field is date_added_facet" do
      let(:footer_field) { "date_added_facet" }
      let(:document) { SolrDocument.new({ "date_added_facet" => [17760704] }) }

      it "parses the first date it finds and formats it"  do
        expect(value).to eq("1776-07-04")
      end
    end

    context "field is date_added_facet containing a 0 in the array" do
      let(:footer_field) { "date_added_facet" }
      let(:document) { SolrDocument.new({ "date_added_facet" => [0, 20220914] }) }

      it "removes the 0 from the array and parses date"  do
        expect(value).to eq("2022-09-14")
      end
    end

    context "field is date_added_facet but date cannot be parsed" do
      let(:footer_field) { "date_added_facet" }
      let(:document) { SolrDocument.new({ "date_added_facet" => [20211905] }) }


      it "return an empty string and post a HoneyBadger error"  do
        expect { subject.query_list_footer_value(footer_field) }.to_not raise_error
        expect(value).to eq("")

        notices = Honeybadger::Backend::Test.notifications[:notices].first
        expect(notices.error_message).to eq("Error trying to parse date_added_facet value; @htomren invalid date")
      end
    end

    context "lc_call_number_display and present" do
      let(:footer_field) { "lc_call_number_display" }
      let(:document) { SolrDocument.new({ "lc_call_number_display" => ["foo"] }) }

      it "returns the value" do
        expect(value).to eq("foo")
      end
    end

    context "lc_call_number_display and NOT present" do
      let(:footer_field) { "lc_call_number_display" }
      let(:document) { SolrDocument.new({}) }

      it "returns nil" do
        expect(value).to be_nil
      end
    end
  end
end
