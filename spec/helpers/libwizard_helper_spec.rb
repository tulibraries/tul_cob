# frozen_string_literal: true

require "rails_helper"

RSpec.describe LibwizardHelper, type: :helper do

  describe "#build_guest_login_libwizard_url(document)" do
    let(:controller_name) { "catalog" }
    let(:base_url) { "https://temple.libwizard.com/f/ContinueAsGuest?" }
    let(:constructed_url) { helper.build_guest_login_libwizard_url(document) }
    before do
      allow(helper).to receive(:controller_name) { controller_name }
    end
    context "document is missing all data" do
      let(:document) { SolrDocument.new({}) }
      it "returns a url with no params" do
        expect(constructed_url).to eq base_url
      end
    end
    context "when mappable fields are present" do
      let(:document) {
        SolrDocument.new({
        "title_statement_display" => ["title"],
        "pub_date" => ["2020"],
        "edition_display" => ["1st edition"],
        "id" => "bestIDever",
        "imprint_man_display" => ["do not include"],
        })
      }
      it "maps the expected parameters" do
        expect(constructed_url).to include("rft.title=title")
        expect(constructed_url).to include("rft.date=2020")
        expect(constructed_url).to include("edition=1st+edition")
        expected_rft_id = "rft_id=#{CGI.escape(url_for([document, only_path: false]))}"
        expect(constructed_url).to include(expected_rft_id)
      end
    end
  end

  describe "#build_error_libwizard_url(document)" do
    let(:controller_name) { "catalog" }
    let(:base_url) { "https://temple.libwizard.com/f/LibrarySearchError?" }
    let(:constructed_url) { helper.build_error_libwizard_url(document) }
    before do
      allow(helper).to receive(:controller_name) { controller_name }
    end
    context "document is missing all data" do
      let(:document) { SolrDocument.new({}) }
      it "returns a url with no params" do
        expect(constructed_url).to eq base_url
      end
    end
    context "when mappable fields are present" do
      let(:document) {
        SolrDocument.new({
        "title_statement_display" => ["title"],
        "pub_date" => ["2020"],
        "id" => "bestIDever",
        })
      }
      it "maps the expected parameters" do
        expect(constructed_url).to include("rft.title=title")
        expect(constructed_url).to include("rft.date=2020")
        expected_rft_id = "rft_id=#{CGI.escape(url_for([document, only_path: false]))}"
        expect(constructed_url).to include(expected_rft_id)
      end
    end
  end

  describe "#build_libwizard_url(document)" do
    let(:controller_name) { "catalog" }
    let(:base_url) { "https://temple.libwizard.com/f/LibrarySearchRequest?" }
    let(:constructed_url) { helper.build_libwizard_url(document) }
    before do
      allow(helper).to receive(:controller_name) { controller_name }
    end
    context "document is missing all data" do
      let(:document) { SolrDocument.new({}) }
      it "returns a url with no params" do
        expect(constructed_url).to eq base_url
      end
    end
    context "when mappable fields are present" do
      let(:document) {
        SolrDocument.new({
        "title_statement_display" => ["title"],
        "pub_date" => ["2020"],
        "volume_display" => ["v3"],
        "edition_display" => ["1st edition"],
        "id" => "bestIDever",
        "isbn_display" => ["12345678"],
        "issn_display" => ["4567890123", "9087654321"],
        "oclc_display" => ["98765432"],
        "imprint_display" => ["imprint_display_1", "imprint_display_2"],
        "imprint_prod_display" => ["imprint_prod_display"],
        "imprint_dist_display" => ["imprint_dist_display"],
        "imprint_man_display" => ["imprint_man_display"],
        })
      }
      it "maps the expected parameters" do
        expect(constructed_url).to include("rft.title=title")
        expect(constructed_url).to include("rft.date=2020")
        expect(constructed_url).to include("edition=1st+edition")
        expected_rft_id = "rft_id=#{CGI.escape(url_for([document, only_path: false]))}"
        expect(constructed_url).to include(expected_rft_id)
        expect(constructed_url).to include("rft.isbn=12345678")
        expect(constructed_url).to include("rft.issn=4567890123%2C+9087654321")
        expect(constructed_url).to include("rft.oclcnum=98765432")
        expect(constructed_url).to include("rft.pub=imprint_display_1%2C+imprint_display_2%2C+imprint_prod_display%2C+imprint_dist_display%2C+imprint_man_display")
      end
    end
  end

  describe "#libwizard_tutorial?" do
    before do
      allow(helper).to receive(:params) { params }
    end

    context "params libwizard_tutorial is not set" do
      let(:params) { {} }

      it "returns false with an empty params object method" do
        expect(libwizard_tutorial?).to be(false)
      end
    end

    context "params libwizard_tutorial? is true" do
      let(:params) { { "libwizard_tutorial" => "true" } }

      it "returns true when libwizard_tutorial? param is not 'false'" do
        expect(libwizard_tutorial?).to be(true)
      end
    end

    context "params libwizard_tutorial is false" do
      let(:params) { { "libwizard_tutorial" => "false" } }

      it "returns false with an empty params object method" do
        expect(libwizard_tutorial?).to be(false)
      end
    end
  end
end
