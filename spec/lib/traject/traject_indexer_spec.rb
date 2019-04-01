# frozen_string_literal: true

require "rspec"
require "traject/macros/marc_format_classifier"
require "traject/macros/custom"
require "traject/macros/marc21_semantics"

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
    Class.new(Traject::Indexer)
  end

  let(:records) { Traject::MarcReader.new(file, subject.settings).to_a }

  let(:file) { File.new("spec/fixtures/marc_files/#{path}") }


  subject { test_class.new }

  describe "#extract_title_statement" do
    let(:path) { "title_statement_examples.xml" }

    before(:each) do
      subject.instance_eval do
        to_field "title_statement_display", extract_title_statement

        settings do
          provide "marc_source.type", "xml"
        end
      end
    end

    context "245 field incudes subfield h" do
      it "adds a / before subfield c" do
        expected = { "title_statement_display" => ["Die dritte generation / produziert von der Tango-Film Berlin ; zusammen mit der Pro-Ject Film-Produktion im Filmverlag der Autoren ; musik, Peer Raben ; ausstattung, Raùl Gimenez ; schnitt, Juliane Lorenz ; ein film von Rainer Werner Fassbinder."] }
        expect(subject.map_record(records[0])).to eq(expected)
      end
    end

    context "245 field does NOT incude subfield h" do
      it "does not add a / before subfield c" do
        expected = { "title_statement_display" => ["Printed circuits handbook."] }
        expect(subject.map_record(records[1])).to eq(expected)
      end
    end

    context "245 field has a slash in multiple fields" do
      it "does not display double slashes" do
        expected = { "title_statement_display" => ["Yaju no seishun Youth of the beast / a Janus Films release ; produced by Keinosuke Kubo ; screenplay by Ichoro Ikeda Tadaaki Yamazaki ; directed by Seijun Suzuki."] }
        expect(subject.map_record(records[2])).to eq(expected)
      end
    end
  end

  describe "#extract_creator" do
    let(:path) { "creator_examples.xml" }
    before(:each) do
      subject.instance_eval do
        to_field "creator_field", extract_creator

        settings do
          provide "marc_source.type", "xml"
        end
      end
    end

    context "No name available" do
      it "does not extract a cretor" do
        expect(subject.map_record(records[0])).to eq({})
      end
    end

    context "Tag 100 only with values in all the subfields" do
      it "extracts creator field in an expected way" do
        expected = { "creator_field" => ["a b c q d|e j m n o p"] }
        expect(subject.map_record(records[1])).to eq(expected)
      end
    end

    context "Tag 110 only with values in all the subfields" do
      it "extracts creator field in an expected way" do
        expected = { "creator_field" => ["a b d c|e l m n o p t"] }
        expect(subject.map_record(records[2])).to eq(expected)
      end
    end

    context "Tag 111 only with values in all the subfields" do
      it "extracts creator field in an expected way" do
        expected = { "creator_field" => ["a n d c j|e l o p t"] }
        expect(subject.map_record(records[3])).to eq(expected)
      end
    end

    context "All three creator fields (100, 110, 111) with all values." do
      it "extracts creator fields in an expected way" do
        expected = { "creator_field" => ["a b c q d|e j m n o p",
                                         "a b d c|e l m n o p t",
                                         "a n d c j|e l o p t"] }
        expect(subject.map_record(records[4])).to eq(expected)
      end
    end
  end

  describe "#extract_creator_vern" do
    let(:path) { "creator_vern_examples.xml" }
    before(:each) do
      subject.instance_eval do
        to_field "creator_vern_display", extract_creator_vern

        settings do
          provide "marc_source.type", "xml"
        end
      end
    end

    context "No name available" do
      it "does not extract a creator" do
        expect(subject.map_record(records[0])).to eq({})
      end
    end

    context "Tag 100 only with values in all the subfields" do
      it "extracts creator field in an expected way" do
        expected = { "creator_vern_display" => ["مطبوعات المجمع؛."] }
        expect(subject.map_record(records[1])).to eq(expected)
      end
    end

    context "Tag 110 only with values in all the subfields" do
      it "extracts creator field in an expected way" do
        expected = { "creator_vern_display" => ["مطبوعات المجمع؛. b c d|e l m n o p t"] }
        expect(subject.map_record(records[2])).to eq(expected)
      end
    end

    context "Tag 111 only with values in all the subfields" do
      it "extracts creator field in an expected way" do
        expected = { "creator_vern_display" => ["مطبوعات المجمع؛. b c d|e l m n o p t"] }
        expect(subject.map_record(records[3])).to eq(expected)
      end
    end

    context "All three creator fields (100, 110, 111) with all values." do
      it "extracts creator fields in an expected way" do
        expected = { "creator_vern_display" => ["مطبوعات المجمع؛. b c d q|e j m n o p", "a b c d|e l m n o p t", "a c d|e j l n o p t"] }
        expect(subject.map_record(records[4])).to eq(expected)
      end
    end
  end

  describe "#extract_contributor" do
    let(:path) { "contributor_examples.xml" }
    before(:each) do
      subject.instance_eval do
        to_field "contributor_display", extract_contributor

        settings do
          provide "marc_source.type", "xml"
        end
      end
    end

    context "Contributor fields display multiple subfields" do
      let(:path) { "creator_multiple_subfields.xml" }

      it "extracts subfields multiple times if multiple subfields are present" do
        expected = { "contributor_display" => ["United States. Department of Agriculture. Economic Research Service"] }
        expect(subject.map_record(records[0])).to eq(expected)
      end

      it "does not change order of subfields if something is nil" do
        expected = { "contributor_display" => ["Oliveira, Victor J.|Test Another plain text field", "Two", "Three|Test"] }
        expect(subject.map_record(records[1])).to eq(expected)
      end
    end

    context "No contributor info available" do
      it "does not extract a cretor" do
        expect(subject.map_record(records[0])).to eq({})
      end
    end

    context "Tag 700 contributor with values in all the subfields" do
      it "extracts creator field in an expected way" do
        expected = { "contributor_display" => ["a b c d q|e j l m n o p r t u"] }
        expect(subject.map_record(records[1])).to eq(expected)
      end
    end

    context "Tag 710 contributor with values in all the subfields" do
      it "extracts creator field idisaplayexpected way" do
        expected = { "contributor_display" => ["a b d c|e l m n o p t"] }
        expect(subject.map_record(records[2])).to eq(expected)
      end
    end

    context "Tag 711 contributor with values in all the subfields" do
      it "extracts creator field in an expected way" do
        expected = { "contributor_display" => ["a n d c j|e l o p t"] }
        expect(subject.map_record(records[3])).to eq(expected)
      end
    end

    context "All three contributor fields (700, 710, 711) with all values." do
      it "extracts creator fields display expected way" do
        expected = { "contributor_display" => ["a b c q d|e j l m n o p r t u",
                                         "a b d c|e l m n o p t",
                                         "a n d c j|e l o p t"] }
        expect(subject.map_record(records[4])).to eq(expected)
      end
    end
  end

  describe "#extract_lang" do
    let(:path) { "extract_lang.xml" }
    before(:each) do
      subject.instance_eval do
        to_field "language_facet", extract_lang

        settings do
          provide "marc_source.type", "xml"
        end
      end
    end

    context "no lang (nil)" do
      it "does not error out" do
        expect(subject.map_record(records[0])).to eq({})
      end
    end

    context "041a is 6 chars long" do
      it "only translates first 3 chars" do
        expect(subject.map_record(records[1])).to eq("language_facet" => ["English"])
      end
    end

    context "041d is 6 chars long" do
      it "translates all codes" do
        expect(subject.map_record(records[2])).to eq("language_facet" => ["English", "Spanish"])
      end
    end
  end

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

      context "856 fields with an indicator 1 = 7 are NOT Online" do
        it "only indicator1 value 4 are included in Online records" do
          expect(subject.map_record(records[12])).to_not eq("Online")
        end
      end

      context "856 fields with an indicator 1 = 4 with no subfield u" do
        it "does not throw error with nil subfield u" do
          expect(subject.map_record(records[13])).to_not eq("Online")
        end
      end

      context "856 fields with correct indactors are Online" do
        it "indicator1 = 4 and indicator2 = NOT 2 maps to Online" do
          expect(subject.map_record(records[14])).to eq("availability_facet" => ["Online"])
        end
      end

      context "records with a PRT subfield 9 that equals Not Available are NOT Online" do
        it "does not map to Online" do
          expect(subject.map_record(records[16])).to_not eq("availability_facet" => ["Online"])
        end
      end

      context "Archive-it links are NOT Online" do
        it "does not include ARCHIVE_IT_LINKS in Online records" do
          expect(subject.map_record(records[9])).to_not eq("availability_facet" => ["Online"])
        end
      end

      describe "#extract_availability(purchase on demand)" do
        let (:record) { MARC::XMLReader.new(StringIO.new(record_text)).first }

        before do
          subject.instance_eval do
            to_field("availability_facet", extract_availability)
            settings do
              provide "marc_source.type", "xml"
            end
          end
        end

        context "with purchase order field true" do
          let(:record_text) { "
<record>
  <datafield ind1='1' ind2=' ' tag='902'>
    <subfield code='a'>EBC-POD</subfield>
    <subfield code='d'>d</subfield>
  </datafield>
  <datafield ind1='1' ind2=' ' tag='100'>
    <subfield code='a'>Foo</subfield>
    <subfield code='q'>q</subfield>
  </datafield>
</record>
                         " }

          it "adds a purchase order availability" do
            expect(subject.map_record(record)["availability_facet"]).to include("Request Rapid Access")
          end

          it "also adds an online availability" do
            expect(subject.map_record(record)["availability_facet"]).to include("Online")
          end
        end

        context "with purchase order field false" do
          let(:record_text) { "
<record>
</record>
                         " }

          it "does not add purchase order availability" do
            expect(subject.map_record(record)).to eq({})
          end
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
              "electronic_resource_display" => [ { portfolio_id: "foo" }.to_json ]
            )
          end
        end

        context "multiple PRT fields present" do
          it "maps a multiple PRT fields to electronic_resource_display" do
            expect(subject.map_record(records[2])).to eq(
              "electronic_resource_display" => [
                { portfolio_id: "foo", availability: "Available" }.to_json,
                { portfolio_id: "bar", availability: "Not Available" }.to_json,
              ]
            )
          end
        end
      end

      context "Only 856 fields are present" do
        context "single 856 field (ind1 = 4; ind2 = not 2) and no exceptions" do
          it "maps a single 856 field to electronic_resource_display" do
            expect(subject.map_record(records[3])).to eq(
              "electronic_resource_display" => [
                { title: "foo", url: "http://foobar.com" }.to_json,
              ]
            )
          end
        end

        context "multiple 856 fields (ind1=4; ind2 not 2) and no exceptions" do
          it "maps multiple 856 fields to electronic_resource_display" do
            expect(subject.map_record(records[4])).to eq(
              "electronic_resource_display" => [
                { title: "z 3", url: "http://foobar.com" }.to_json,
                { title: "y", url: "http://foobar.com" }.to_json,
                { title: "Link to Resource", url: "http://foobar.com" }.to_json,
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
            expect(subject.map_record(records[15])).to eq({})
          end
        end
      end

      context "Both PRT and 856 fields are present" do
        context "856 field has exception" do
          it "only maps the PRT field to electronic_resource_display" do
            expect(subject.map_record(records[7])).to eq(
              "electronic_resource_display" => [ { portfolio_id: "foo" }.to_json ]
            )
          end
        end
        context "856 has no exception" do
          it "only maps the PRT field to electronic_resource_display" do
            expect(subject.map_record(records[8])).to eq(
              "electronic_resource_display" => [ { portfolio_id: "foo" }.to_json ]
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
            expect(subject.map_record(records[10])).to eq("url_more_links_display" => [ { title: "Archive", url: "http://archive-it.org/collections/4222" }.to_json ])
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
              "url_more_links_display" => [ { title: "book review", url: "http://foobar.com" }.to_json ],
            )
          end
        end

      end

      context "Both PRT and 856 fields are present" do
        context "856 field has exception" do
          it "only maps the PRT field to url_more_links_display" do
            expect(subject.map_record(records[7])).to eq(
              "url_more_links_display" => [ { title: "BOOK review", url: "http://foobar.com" }.to_json ]
            )
          end
        end
        context "856 has no exception" do
          it "only maps the PRT field to url_more_links_display" do
            expect(subject.map_record(records[8])).to eq(
              "url_more_links_display" => [ { title: "bar", url: "http://foobar.com" }.to_json ]
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
        it "it does not map to url_finding_aid_display " do
          expect(subject.map_record(records[11])).to eq(
            "url_finding_aid_display" => [ { title: "Finding aid", url: "http://library.temple.edu/scrc" }.to_json ])
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
            "url_more_links_display" => [
                { portfolio_id: "bar", availability: "Not Available" }.to_json,
                { portfolio_id: "foo", availability: "Available" }.to_json,
            ]
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


  describe "#extract_subject_display" do
    before do
      subject.instance_eval do
        to_field "subject_display", extract_subject_display
        settings do
          provide "marc_source.type", "xml"
        end
      end
    end

    context "when a record doesn't have subject topics" do
      let(:path) { "subject_topic_missing.xml" }
      it "does not map a subject_display" do
        expect(subject.map_record(records[0])).to eq({})
      end
    end

    context "when a record has subjects" do
      let(:path) { "subject_display.xml" }
      it "maps data from 6XX fields in expected way" do
        expected = [
          "Kennedy, John F. (John Fitzgerald), 1917-1963 — Pictorial works",
          "Onassis, Jacqueline Kennedy, 1929- — Pictorial works",
          "Kennedy, John F. (John Fitzgerald), 1917-1963 — Assassination — Pictorial works",
          "Presidents — United States — Pictorial works",
          "Presidents' spouses — United States — Pictorial works",
          "Photography — Social aspects — United States — History — 20th century",
          "Mass media — Social aspects — United States — History — 20th century",
          "Popular culture — United States — History — 20th century",
          "Art and popular culture — United States — History — 20th century",
          "United States — Civilization — 1945-",
          "Kennedy family"
        ]
        expect(subject.map_record(records[0])).to eq(
          "subject_display" => expected
        )
      end
    end
  end

  describe "#extract_genre_display" do
    before do
      subject.instance_eval do
        to_field "genre_display", extract_genre_display
        settings do
          provide "marc_source.type", "xml"
        end
      end
    end

    context "when a record doesn't have genres" do
      let(:path) { "genre_display.xml" }
      it "does not map a genre_display" do
        expect(subject.map_record(records[0])).to eq({})
      end
    end

    context "when a record has genres" do
      let(:path) { "genre_display.xml" }
      it "maps data from 655 fields in expected way" do
        expected = [
          "Documentary films",
          "Foreign language films — Chinese"
        ]
        expect(subject.map_record(records[1])).to eq(
          "genre_display" => expected
        )
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
          "subject_topic_facet" => ["The Queen is Dead — Meat is Murder"]
        )
      end

      it "maps data from the 600 to the expected field" do
        expect(subject.map_record(records[1])).to eq(
          # Note that value is flattened
          "subject_topic_facet" => ["Subject Topic moves on to the year 3000"]
          )
      end
    end
  end

  describe "#libraries_based_negative_boost" do
    let(:path) { "libraries.xml" }
    before(:each) do
      subject.instance_eval do
        to_field "libraries_based_boost_t", library_based_boost
        settings do
          provide "marc_source.type", "xml"
        end
      end
    end

    context "when Presser is the only library" do
      it "returns negative_boost" do
        expect(subject.map_record(records[0])).to eq("libraries_based_boost_t" => ["no_boost"])
      end
    end

    context "when Presser is not present" do
      it "returns boost" do
        expect(subject.map_record(records[1])).to eq("libraries_based_boost_t" => ["boost"])
      end
    end

    context "when Presser and another library are both present, with presser first" do
      it "returns boost" do
        expect(subject.map_record(records[2])).to eq("libraries_based_boost_t" => ["boost"])
      end
    end

    context "when Presser and another library are both present, with the other library first" do
      it "returns boost" do
        expect(subject.map_record(records[3])).to eq("libraries_based_boost_t" => ["boost"])
      end
    end
  end

  describe "#suppress_items" do
    let(:path) { "lost_missing_technical.xml" }

    before do
      subject.instance_eval do
        to_field "suppress_items_b", suppress_items
        settings do
          provide "marc_source.type", "xml"
        end
      end
    end

    context "when a single item is lost" do
      it "maps lost record" do
        expect(subject.map_record(records[0])).to eq("suppress_items_b" => [true])
      end
    end

    context "when a single item is missing" do
      it "maps missing record" do
        expect(subject.map_record(records[1])).to eq("suppress_items_b" => [true])
      end
    end

    context "when a single item is technical" do
      it "maps technical record" do
        expect(subject.map_record(records[2])).to eq("suppress_items_b" => [true])
      end
    end

    context "when there are multiple items and one of the records is lost" do
      it "does not map to the field" do
        expect(subject.map_record(records[3])).to eq({})
      end
    end

    context "when there are multiple items and one of the records is in asrs" do
      it "does not map to the field" do
        expect(subject.map_record(records[4])).to eq({})
      end
    end
  end

  describe "full reindex #suppress_items" do
    let(:path) { "lost_missing_technical.xml" }


    before do
      stub_const("ENV", ENV.to_hash.merge("TRAJECT_FULL_REINDEX" => "yes"))
      @writer = Traject::ArrayWriter.new
      @indexer = Traject::Indexer.new(writer: @writer) do
        to_field "suppress_items_b", suppress_items
      end

      subject.instance_eval do
        settings do
          provide "marc_source.type", "xml"
        end
      end
    end

    context "when a single item is lost" do
      it "maps lost record" do
        expect(@indexer.process_record(records[0]).skip?).to eq(true)
      end
    end

    context "when a single item is missing" do
      it "maps  record" do
        expect(@indexer.process_record(records[1]).skip?).to eq(true)
      end
    end

    context "when a single item is technical" do
      it "maps technical record" do
        expect(@indexer.process_record(records[2]).skip?).to eq(true)
      end
    end

    context "when there are multiple items and one of the records is lost" do
      it "does not map to the field" do
        expect(@indexer.process_record(records[3]).skip?).to eq(false)
      end
    end

    context "when there are multiple items and one of the records is in asrs" do
      it "does not map to the field" do
        expect(@indexer.process_record(records[4]).skip?).to eq(false)
      end
    end
  end

  describe "#extract_oclc_number" do
    let(:path) { "oclc.xml" }

    before do
      subject.instance_eval do
        to_field "oclc_number_display", extract_oclc_number
        settings do
          provide "marc_source.type", "xml"
        end
      end
    end

    context "when there is no 035 or 979 field" do
      it "does not map record" do
        expect(subject.map_record(records[0])).to eq({})
      end
    end

    context "when 035 field includes OCoLC" do
      it "maps record" do
        expect(subject.map_record(records[1])).to eq("oclc_number_display" => ["1042418854"])
      end
    end

    context "when 979 field includes OCoLC" do
      it "maps record" do
        expect(subject.map_record(records[2])).to eq("oclc_number_display" => ["1042418854"])
      end
    end

    context "when 979 field and 035 field includes OCoLC" do
      it "maps record" do
        expect(subject.map_record(records[3])).to eq("oclc_number_display" => ["1042418854"])
      end
    end

    context "when 979 field includes ocn" do
      it "maps record" do
        expect(subject.map_record(records[4])).to eq("oclc_number_display" => ["986990990"])
      end
    end

    context "when 979 field includes on" do
      it "maps record" do
        expect(subject.map_record(records[5])).to eq("oclc_number_display" => ["1012488209"])
      end
    end

    context "when 979 field includes on inside a string" do
      it "does not map record" do
        expect(subject.map_record(records[8])).to eq({})
      end
    end

    context "when 979 field and 035 field have different OCLC numbers" do
      it "maps record" do
        expect(subject.map_record(records[6])).to eq("oclc_number_display" => ["938995310", "882543310"])
      end
    end

    context "when 035 field includes subfield 9 with ExL" do
      it "does not map record" do
        expect(subject.map_record(records[7])).to eq({})
      end
    end
  end

  describe "#extract_work_access_point" do
    let (:record) { MARC::XMLReader.new(StringIO.new(record_text)).first }

    before do
      subject.instance_eval do
        to_field "work_access_point", extract_work_access_point
        settings do
          provide "marc_source.type", "xml"
        end
      end
    end

    context "All fields available" do
      let(:record_text) { "
<record>
  <datafield ind1='1' ind2=' ' tag='130'>
    <subfield code='a'>a</subfield>
    <subfield code='d'>d</subfield>
  </datafield>
  <datafield ind1='1' ind2=' ' tag='100'>
    <subfield code='a'>a</subfield>
    <subfield code='q'>q</subfield>
  </datafield>
  <datafield ind1='1' ind2=' ' tag='110'>
    <subfield code='a'>a</subfield>
    <subfield code='d'>d</subfield>
  </datafield>
  <datafield ind1='1' ind2=' ' tag='240'>
    <subfield code='a'>a</subfield>
    <subfield code='s'>s</subfield>
  </datafield>
  <datafield ind1='1' ind2=' ' tag='245'>
    <subfield code='a'>a</subfield>
    <subfield code='p'>p</subfield>
  </datafield>
</record>
                     " }

      it "maps only the 130 field" do
        expect(subject.map_record(record)).to eq("work_access_point" => ["a d"])
      end
    end

    context "Only 130 not available" do
      let(:record_text) { "
<record>
  <datafield ind1='1' ind2=' ' tag='100'>
    <subfield code='a'>a</subfield>
    <subfield code='q'>q</subfield>
  </datafield>
  <datafield ind1='1' ind2=' ' tag='110'>
    <subfield code='a'>a</subfield>
    <subfield code='d'>d</subfield>
  </datafield>
  <datafield ind1='1' ind2=' ' tag='240'>
    <subfield code='a'>a</subfield>
    <subfield code='s'>s</subfield>
  </datafield>
  <datafield ind1='1' ind2=' ' tag='245'>
    <subfield code='a'>a</subfield>
    <subfield code='p'>p</subfield>
  </datafield>
</record>
                     " }

      it "maps 100 . 240" do
        expect(subject.map_record(record)).to eq("work_access_point" => ["a q . a s"])
      end
    end

    context "Only 130 and 100 not available" do
      let(:record_text) { "
<record>
  <datafield ind1='1' ind2=' ' tag='110'>
    <subfield code='a'>a</subfield>
    <subfield code='d'>d</subfield>
  </datafield>
  <datafield ind1='1' ind2=' ' tag='240'>
    <subfield code='a'>a</subfield>
    <subfield code='s'>s</subfield>
  </datafield>
  <datafield ind1='1' ind2=' ' tag='245'>
    <subfield code='a'>a</subfield>
    <subfield code='p'>p</subfield>
  </datafield>
</record>
                     " }

      it "maps 110 . 240" do
        expect(subject.map_record(record)).to eq("work_access_point" => ["a d . a s"])
      end
    end

    context "Only 130 and 240 not available" do
      let(:record_text) { "
<record>
  <datafield ind1='1' ind2=' ' tag='100'>
    <subfield code='a'>a</subfield>
    <subfield code='q'>q</subfield>
  </datafield>
  <datafield ind1='1' ind2=' ' tag='110'>
    <subfield code='a'>a</subfield>
    <subfield code='d'>d</subfield>
  </datafield>
  <datafield ind1='1' ind2=' ' tag='245'>
    <subfield code='a'>a</subfield>
    <subfield code='p'>p</subfield>
  </datafield>
</record>
                     " }

      it "maps 100 . 245" do
        expect(subject.map_record(record)).to eq("work_access_point" => ["a q . a p"])
      end
    end

    context "Only 130 and 240 not available" do
      let(:record_text) { "
<record>
  <datafield ind1='1' ind2=' ' tag='100'>
    <subfield code='a'>a</subfield>
    <subfield code='q'>q</subfield>
  </datafield>
  <datafield ind1='1' ind2=' ' tag='110'>
    <subfield code='a'>a</subfield>
    <subfield code='d'>d</subfield>
  </datafield>
  <datafield ind1='1' ind2=' ' tag='245'>
    <subfield code='a'>a</subfield>
    <subfield code='p'>p</subfield>
  </datafield>
</record>
                     " }

      it "maps 100 . 245" do
        expect(subject.map_record(record)).to eq("work_access_point" => ["a q . a p"])
      end
    end

    context "130, 240 and 100 not available" do
      let(:record_text) { "
<record>
  <datafield ind1='1' ind2=' ' tag='110'>
    <subfield code='a'>a</subfield>
    <subfield code='d'>d</subfield>
  </datafield>
  <datafield ind1='1' ind2=' ' tag='245'>
    <subfield code='a'>a</subfield>
    <subfield code='p'>p</subfield>
  </datafield>
</record>
                     " }

      it "maps 110 . 245" do
        expect(subject.map_record(record)).to eq("work_access_point" => ["a d . a p"])
      end
    end

    context "130, 240, 100, 110 not available" do
      let(:record_text) { "
<record>
  <datafield ind1='1' ind2=' ' tag='245'>
    <subfield code='a'>a</subfield>
    <subfield code='p'>p</subfield>
  </datafield>
</record>
                     " }

      it "skips the map" do
        expect(subject.map_record(record)).to eq({})
      end
    end
  end

  describe "#extract_purchase_order" do
    let (:record) { MARC::XMLReader.new(StringIO.new(record_text)).first }

    before do
      subject.instance_eval do
        to_field "purchase_order", extract_purchase_order
        settings do
          provide "marc_source.type", "xml"
        end
      end
    end

    context "with mathing 902a field" do
      let(:record_text) { "
<record>
  <datafield ind1='1' ind2=' ' tag='902'>
    <subfield code='a'>EBC-POD</subfield>
    <subfield code='d'>d</subfield>
  </datafield>
  <datafield ind1='1' ind2=' ' tag='100'>
    <subfield code='a'>Foo</subfield>
    <subfield code='q'>q</subfield>
  </datafield>
</record>
                     " }

      it "maps to true" do
        expect(subject.map_record(record)).to eq("purchase_order" => [true])
      end
    end

    context "without a matching 902a field" do
      let(:record_text) { "
<record>
  <datafield ind1='1' ind2=' ' tag='902'>
    <subfield code='a'>Buzz</subfield>
    <subfield code='d'>d</subfield>
  </datafield>
  <datafield ind1='1' ind2=' ' tag='100'>
    <subfield code='a'>Foo</subfield>
    <subfield code='q'>q</subfield>
  </datafield>
</record>
                     " }

      it "maps to false" do
        expect(subject.map_record(record)).to eq("purchase_order" => [false])
      end
    end

    context "without a 902a field" do
      let(:record_text) { "
<record>
</record>
                     " }

      it "maps to false" do
        expect(subject.map_record(record)).to eq("purchase_order" => [false])
      end
    end
  end

end
