# frozen_string_literal: true

require "rails_helper"

RSpec.describe HathitrustHelper, type: :helper do
  describe "#build_hathitrust_url(field)" do
    let(:field) { { "bib_key" => "000005117", "access" => "allow" } }
    let(:base_url) { "https://catalog.hathitrust.org/Record/000005117?signon=swle:https://fim.temple.edu/idp/shibboleth" }
    let(:constructed_url) { helper.build_hathitrust_url(field) }

    it "returns a correctly formed url" do
      expect(constructed_url).to eq base_url
    end
  end

  describe "#hathitrust_link_allowed?(document))" do
    context "record has a hathi_trust_bib_key_display field" do
      context "with allow access" do
        let(:document) { { "hathi_trust_bib_key_display" => [ { "bib_key" => "000005117", "access" => "allow" } ] } }

        it "returns true" do
          expect(hathitrust_link_allowed?(document)).to be(true)
        end
      end

      context "with deny access" do
        let(:document) { { "hathi_trust_bib_key_display" => [ { "bib_key" => "000005117", "access" => "deny" }] } }

        it "does not render the online partial" do
          expect(hathitrust_link_allowed?(document)).to be(false)
        end
      end
    end
  end

  describe "#render_hathitrust_display(document)" do
    context "record has a hathi_trust_bib_key_display field" do
      context "with allow access" do
        let(:document) { { "hathi_trust_bib_key_display" => [ { "bib_key" => "000005117", "access" => "allow" } ] } }

        it "renders the online partial" do
          expect(helper.render_hathitrust_display(document)).not_to be_nil
        end
      end

      context "with deny access" do
        let(:document) { { "hathi_trust_bib_key_display" => [ { "bib_key" => "000005117", "access" => "deny" }] } }

        it "does not render the online partial" do
          expect(helper.render_hathitrust_display(document)).to be_nil
        end

        context "when campus closed flag is true" do
          it "renders the online partial" do
            allow(helper).to receive(:campus_closed?).and_return("true")
            expect(helper.render_hathitrust_display(document)).not_to be_nil
          end
        end
      end
    end
  end
end
