require 'rspec'
require 'traject/macros/marc_format_classifier'
include Traject::Macros::MarcFormats

RSpec.describe "four_digit_year(field):" do
  describe "four_digit_year(field)" do
    it "returns nil if given nil" do
      expect(four_digit_year nil).to eq(nil)
    end

    it "returns nil if given empty string" do
      expect(four_digit_year "").to eq(nil)
      expect(four_digit_year "\n").to eq(nil)
      expect(four_digit_year "\n\n").to eq(nil)
      expect(four_digit_year "      ").to eq(nil)
    end

    it "returns nil for Roman Numerals" do
      expect(four_digit_year "MCCXLV").to eq(nil)
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
