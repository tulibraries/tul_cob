# frozen_string_literal: true

require "rspec"
require "traject/macros/marc_format_classifier"
require "traject/macros/custom"

require "traject/indexer"
require "marc/record"

include Traject::Macros::MarcFormats
include Traject::Macros::Custom

RSpec.describe "custom methods" do

  describe "#four_digit_year(field):" do
    describe "#four_digit_year(field)" do
      context "when field is nil" do
        it "returns nil" do
          expect(four_digit_year nil).to eq(nil)
        end
      end

      context "when given an empty string" do
        it "returns nil" do
          expect(four_digit_year "").to eq(nil)
          expect(four_digit_year "\n").to eq(nil)
          expect(four_digit_year "\n\n").to eq(nil)
          expect(four_digit_year "      ").to eq(nil)
        end
      end

      context "when contains Roman Numerals" do
        it "returns nil" do
          expect(four_digit_year "MCCXLV").to eq(nil)
        end
      end

      it "returns nil for [n.d.],''" do
        expect(four_digit_year '[n.d.],""').to eq(nil)
      end

      it "extracts year from MCCXLV [1745],1745" do
        expect(four_digit_year "MCCXLV [1745],1745").to eq("1745")
      end

      it "extracts the first possible 4 digit numeral" do
        expect(four_digit_year "1918-1966.,1918   ").to eq("1918")
      end

      it "extracts the first possible 4 digit numeral" do
        expect(four_digit_year "'18-1966.,1918   ").to eq("1966")
        expect(four_digit_year "c1993.,1993").to eq("1993")
        expect(four_digit_year "©2012,2012").to eq("2012")
      end
    end
  end

  describe "#to_marc_normalized" do
    describe "#flank(field)" do
      let(:input) {}
      subject { Traject::Macros::Custom.flank input }
      context "nil" do
        it "returns an empty string" do
          expect(subject).to be_nil
        end
      end

      context "empty string" do
        let(:input) { "" }
        it "returns an empty string" do
          expect(subject).to eq("")
        end
      end

      context "non empty string" do
        let(:input) { "foo" }
        it "returns a flanked string" do
          expect(subject).to eq("matchbeginswith foo matchendswith")
        end
      end

      context "a string that is flanked" do
        let(:input) { "matchbeginswith foo matchendswith" }
        it "does not reflank a string" do
          expect(subject).to eq(input)
        end
      end
    end
  end

  describe "#creator_name_trim_punctuation(name)" do
    context "removes trailing comma, slash" do
      let(:input) { "Richard M. Restak." }
      it "removes trailing period" do
        expect(creator_name_trim_punctuation(input)).to eq("Richard M. Restak")
      end

      let(:input) { "Richard M. Restak," }
      it "removes trailing comma" do
        expect(creator_name_trim_punctuation(input)).to eq("Richard M. Restak")
      end

      let(:input) { "Richard M. Restak/" }
      it "removes trailing slash" do
        expect(creator_name_trim_punctuation(input)).to eq("Richard M. Restak")
      end

      context "keeps period if preceded by characters other than parentheses" do
        let(:input) { "Richard M. Restak" }
        it "retains period after middle initial" do
          expect(creator_name_trim_punctuation(input)).to eq("Richard M. Restak")
        end
      end

      context "removes period following parentheses" do
        let(:input) { "4 Learning (Firm)." }
        it "retains period after middle initial" do
          expect(creator_name_trim_punctuation(input)).to eq("4 Learning (Firm)")
        end
      end
    end
  end
end

RSpec.describe Traject::Macros::Custom do
  let(:test_class) do
    c = Class.new(Traject::Indexer)
    c.send :extend, Traject::Macros::MarcFormats
    c.send :extend, Traject::Macros::Custom
    c
  end

  let(:records) { Traject::MarcReader.new(file, subject.settings).to_a }

  let(:file) { File.new("spec/fixtures/marc_files/#{path}") }


  subject { test_class.new }

  describe "#extract_genre" do
    let(:path) { "genre_facet_examples.xml" }
    before(:each) do
      subject.instance_eval do
        to_field "genre_facet", extract_genre

        settings do
          provide "marc_source.type", "xml"
        end
      end
    end

    context "String not found in GENRE_STOP_WORDS" do
      it "does map a field to genre_facet" do
        expect(subject.map_record(records[0])).to eq("genre_facet" => ["Drama"])
      end
    end

    context "String found in GENRE_STOP_WORDS" do
      it "does not map a field to genre_facet" do
        expect(subject.map_record(records[1])).to eq({})
      end
    end


  end

  context "electronic resource macros" do
    let(:path) { "url_field_examples.xml" }

    describe "#extract_availability" do
      before(:each) do
        subject.instance_eval do
          to_field "availability_facet", extract_availability

          settings do
            provide "marc_source.type", "xml"
          end
        end
      end

      context "Archive-it links are NOT Online" do
        it "does not include ARCHIVE_IT_LINKS in Online records" do
          expect(subject.map_record(records[9])).to_not eq("Online")
        end
      end
    end

    describe "#extract_electronic_resource" do
      before(:each) do
        subject.instance_eval do
          to_field "electronic_resource_display", extract_electronic_resource

          settings do
            provide "marc_source.type", "xml"
          end
        end
      end

      context "Neither PRT nor 856 fields are present" do
        it "does not map a field to electronic_resource_display" do
          expect(subject.map_record(records[0])).to eq({})
        end
      end

      context "Only PRT fields are present" do
        context "single PRT field to electronic_resource_display" do
          it "maps a single PRT field" do
            expect(subject.map_record(records[1])).to eq(
              "electronic_resource_display" => ["foo"]
            )
          end
        end

        context "multiple PRT fields present" do
          it "maps a multiple PRT fields to electronic_resource_display" do
            expect(subject.map_record(records[2])).to eq(
              "electronic_resource_display" => ["foo", "bar"]
            )
          end
        end
      end

      context "Only 856 fields are present" do
        context "single 856 field (ind1 = 4; ind2 = not 2) and no exceptions" do
          it "maps a single 856 field to electronic_resource_display" do
            expect(subject.map_record(records[3])).to eq(
              "electronic_resource_display" => ["foo|http://foobar.com"]
            )
          end
        end

        context "multiple 856 fields (ind1=4; ind2 not 2) and no exceptions" do
          it "maps multiple 856 fields to electronic_resource_display" do
            expect(subject.map_record(records[4])).to eq(
              "electronic_resource_display" => [
                "z 3|http://foobar.com",
                "y|http://foobar.com",
                "Link to Resource|http://foobar.com"
              ]
            )
          end
        end

        context "single 856 field (ind1 = 4; ind2 = not 2) with exception" do
          it "does not map a field to electronic_resource_display" do
            expect(subject.map_record(records[5])).to eq({})
          end
        end

        context "multiple 856 fields (ind1 = 4; ind2 = not 2) with exceptions" do
          it "does not map a field to electronic_resource_display" do
            expect(subject.map_record(records[6])).to eq({})
          end
        end
      end

      context "Both PRT and 856 fields are present" do
        context "856 field has exception" do
          it "only maps the PRT field to electronic_resource_display" do
            expect(subject.map_record(records[7])).to eq(
              "electronic_resource_display" => ["foo"]
            )
          end
        end
        context "856 has no exception" do
          it "only maps the PRT field to electronic_resource_display" do
            expect(subject.map_record(records[8])).to eq(
              "electronic_resource_display" => ["foo"]
            )
          end
        end
      end
    end

    describe "#extract_url_more_links" do
      before(:each) do
        subject.instance_eval do
          to_field "url_more_links_display", extract_url_more_links

          settings do
            provide "marc_source.type", "xml"
          end
        end
      end

      context "Neither PRT nor 856 fields are present" do
        it "it does not map a url_more_links_display" do
          expect(subject.map_record(records[0])).to eq({})
        end
      end

      context "Only a PRT field is present" do
        context "single PRT field" do
          it "does not map a field to url_more_links_display" do
            expect(subject.map_record(records[1])).to eq({})
          end
        end
      end

      context "Only 856 field is present" do
        context "single 856 field (ind1 = 4; ind2 = not 2) with no exceptions" do
          it "maps a single 856 field to url_more_links_display" do
            expect(subject.map_record(records[3])).to eq({})
          end
        end

        context "single 856 field (ind1 = 4; ind2 = not 2) with archive-it exception" do
          it "maps a single 856 field to url_more_links_display" do
            expect(subject.map_record(records[10])).to eq("url_more_links_display" => ["Archive|http://archive-it.org/collections/4222"])
          end
        end

        context "single 856 field (ind1 = 4; ind2 = not 2) with temple and scrc should not map to more_links" do
        it "does not include Temple SCRC resources in url_more_links_display" do
          expect(subject.map_record(records[11])).to eq({})
        end
      end

        context "single 856 field (ind1 = 4; ind2 = not 2) with exceptions" do
          it "maps a single 856 field to url_more_links_display" do
            expect(subject.map_record(records[5])).to eq(
              "url_more_links_display" => ["book review|http://foobar.com"],
            )
          end
        end
      end

      context "Both PRT and 856 fields are present" do
        context "856 field has exception" do
          it "only maps the PRT field to url_more_links_display" do
            expect(subject.map_record(records[7])).to eq(
              "url_more_links_display" => ["BOOK review|http://foobar.com"]
            )
          end
        end
        context "856 has no exception" do
          it "only maps the PRT field to url_more_links_display" do
            expect(subject.map_record(records[8])).to eq(
              "url_more_links_display" => ["bar|http://foobar.com"]
            )
          end
        end
      end
    end

    describe "#extract_url_finding_aid" do
      before(:each) do
        subject.instance_eval do
          to_field "url_finding_aid_display", extract_url_finding_aid

          settings do
            provide "marc_source.type", "xml"
          end
        end
      end

      context "856 field includes temple and scrc" do
        it "it maps to url_finding_aid_display" do
          expect(subject.map_record(records[11])).to eq(
            "url_finding_aid_display" => ["Finding aid|http://library.temple.edu/scrc"])

        end
      end
    end

    describe "#sort_electronic_resource" do
      before(:each) do
        subject.instance_eval do
          to_field "url_more_links_display", extract_electronic_resource, &sort_electronic_resource!

          settings do
            provide "marc_source.type", "xml"
          end
        end
      end

      context "multiple PRT fields present" do
        it "reverses the order of multipe PRT fields" do
          expect(subject.map_record(records[2])).to eq(
            "url_more_links_display" => ["bar", "foo"]
          )
        end
      end

      context "An empty set" do
        it "handles an empty accumulator correctly" do
          acc = []
          rec = []
          context = nil
          expect(sort_electronic_resource![acc, rec, context]).to eq([])
        end
      end
    end
  end


  describe "#extract_subject_topic_facet" do
    before do
      subject.instance_eval do
        to_field "subject_topic_facet", extract_subject_topic_facet
        settings do
          provide "marc_source.type", "xml"
        end
      end
    end

    context "when a record doesn't have subject topics" do
      let(:path) { "subject_topic_missing.xml" }
      it "does not raise an error" do
        expect { subject.map_record(records[0]) }.not_to raise_error
      end

      it "does not map anything to the field" do
        expect(subject.map_record(records[0])).to eq({})
      end
    end

    context "when a record has subject topics" do
      let(:path) { "subject_topic.xml" }
      it "maps data from 650 to the expected field" do
        expect(subject.map_record(records[0])).to eq(
          "subject_topic_facet" => ["The Queen is Dead--Meat is Murder"]
        )
      end

      it "maps data from the 600 to the expected field" do
        expect(subject.map_record(records[1])).to eq(
          "subject_topic_facet" => [["Subject Topic moves on to the year 3000"]]
          )
      end


    end
  end
end
