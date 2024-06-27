# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lookupable, type: :model do

  subject { document.extend(Lookupable) }
  let(:document) { SolrDocument.new({}) }

  describe "#location_name_from_short_codes(location_code, library_code)" do
    context "location codes are converted to names using translation map" do
      let(:library_code) { "SCRC" }
      let(:location_code) { "rarestacks" }

      it "displays location name" do
        expect(document.location_name_from_short_codes(location_code, library_code)).to eq "Reading Room"
      end
    end
  end

  describe "#library_name_from_short_code(short_code)" do
    context "library codes are converted to names using translation map" do
      let(:short_code) { "MAIN" }
      it "displays library name" do
        expect(document.library_name_from_short_code(short_code)).to eq "Charles Library"
      end
    end
  end

end
