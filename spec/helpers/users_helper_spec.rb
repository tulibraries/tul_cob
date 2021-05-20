# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersHelper, type: :helper do
  describe "#make_date" do
    it "returns a date in the correct timezone" do
      iso8601_dt = "2018-10-16T02:00:00Z"
      expect(make_date(iso8601_dt)).to eql "10/15/2018"
    end
  end

  describe "wrong iso8601 formatted date returned by Alma" do
    context "Properly formatted ISO8601" do
      Hold = Struct.new(:expiry_date)
      hold = Hold.new("2020-09-01")

      it "returns a valid time" do
        expect(Honeybadger).to_not receive(:notify)
        expect(expiry_date(hold)).to eq "08/31/2020"
      end
    end

    context "Improperly formatted ISO8601 date" do
      Hold = Struct.new(:expiry_date)
      hold = Hold.new("2020-09-01Z")

      it "returns a valid time anyway" do
        expect(Honeybadger).to_not receive(:notify)
        expect(expiry_date(hold)).to eq "08/31/2020"
      end
    end

    context "Full date time" do
      Hold = Struct.new(:expiry_date)
      hold = Hold.new("2018-10-16T02:00:00Z")

      it "returns N/A" do
        expect(Honeybadger).to_not receive(:notify)
        expect(expiry_date(hold)).to eq "10/15/2018"
      end
    end

    context "No expiry date" do
      Hold = Struct.new(:expiry_date)
      hold = Hold.new("")

      it "returns N/A" do
        expect(Honeybadger).to_not receive(:notify)
        expect(expiry_date(hold)).to eq "N/A"
      end
    end

    context "No expiry date" do
      Hold = Struct.new(:expiry_date)
      hold = Hold.new(nil)

      it "returns N/A" do
        expect(Honeybadger).to_not receive(:notify)
        expect(expiry_date(hold)).to eq "N/A"
      end
    end

    context "non-date eiding with a 'Z'" do
      Hold = Struct.new(:expiry_date)
      hold = Hold.new("XYZ")

      it "returns N/A" do
        expect(Honeybadger).to receive(:notify)
        expect(expiry_date(hold)).to eq "N/A"
      end
    end
  end

  describe "student_faculty_login_uri" do
    before(:each) do
      without_partial_double_verification do
        allow(helper).to receive(:resource_name) { "user" }
      end
    end

    context "not configured for SAML auth" do
      it "uses the shibboleth login by default" do
        expect(helper.student_faculty_login_uri).to eq("/users/auth/shibboleth")
      end
    end

    context "SAML auth configured" do
      it "uses the saml login" do
        allow(Rails.configuration).to receive(:devise) { { "saml_certificate" => "foo" } }
        expect(helper.student_faculty_login_uri).to eq("/users/auth/saml")
      end
    end
  end
end
