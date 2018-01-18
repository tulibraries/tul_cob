# frozen_string_literal: true

require "rspec"
require "traject/macros/marc_format_classifier"
require "traject/macros/custom"
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
