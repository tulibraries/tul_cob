# frozen_string_literal: true

require "rails_helper"

# Specs in this file have access to a helper object that includes
# the CatalogHelper. For example:
#
# describe CatalogHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end

RSpec.describe CatalogHelper, type: :helper do
  describe "#isbn_data_attribute" do
    context "document contains an isbn" do
      let(:document) { { isbn_display: ["123456789"] } }
      it "returns the data-isbn string" do
        expect(isbn_data_attribute(document)).to eql "data-isbn=123456789"
      end
    end

    context "document contains multiple isbn" do
      let(:document) { { isbn_display: ["23445667890", "123456789"] } }
      it "returns the data-isbn string" do
        expect(isbn_data_attribute(document)).to eql "data-isbn=23445667890,123456789"
      end
    end

    context "document contains an isbn" do
      let(:document) { {} }
      it "returns the data-isbn string" do
        expect(isbn_data_attribute(document)).to be_nil
      end
    end
  end

  describe "#grouped_citations" do
    it "sends all the given document citations to the grouped_citations method of the Citation class" do
      documents = [
        double("Document", citations: :abc),
        double("Document", citations: :def)
      ]
      expect(Citation).to receive(:grouped_citations).with([:abc, :def])
      grouped_citations(documents)
    end
  end

  describe "#render_marc_view" do
    let(:doc) { OpenStruct.new(to_marc: "foo") }

    before(:each) {
      helper.instance_variable_set(:@document, doc)
      allow(helper).to receive(:render) {}
      helper.render_marc_view
    }

    context "document responds to to_marc" do
      it "renders the marc_view template" do
        expect(helper).to have_received(:render).with("marc_view")
      end
    end

    context "document does not respond to to_marc" do
      let(:doc) { double }

      it "renders a default no_marc ouput" do
        expect(helper).to_not have_received(:render)
        expect(helper.render_marc_view).to eq(helper.t("blacklight.search.librarian_view.empty"))
      end
    end
  end

  describe "#render_availability" do
    let(:doc) { SolrDocument.new(purchase_order: true) }
    let(:presenter) { CatalogIndexPresenter.new(doc, self) }
    let(:blacklight_config) { CatalogController.blacklight_config }
    let(:user) { FactoryBot.build(:user) }

    before(:each) do
      allow(presenter).to receive(:purchase_order_button) { "purchase_order_button" }
      allow(helper).to receive(:link_to) { "render_login_link" }
      allow(helper).to receive(:render) { "availability_section" }
      allow(helper).to receive(:current_user) { user }

      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config) { blacklight_config }
      end
    end

    context "document has purchase order and user is not logged in" do
      let(:user) { nil }

      it "should render the log in in link" do
        expect(helper.render_availability(doc, presenter)).to eq("render_login_link")
      end
    end

    context "document has purchase order and user is logged in" do
      it "should render the purchase order button" do
        expect(helper.render_availability(doc, presenter)).to eq("purchase_order_button")
      end
    end

    context "document does not have purchase order button" do
      let(:doc) { SolrDocument.new(purchase_order: false) }
      it "should not render the purchase_order_button" do
        expect(helper.render_availability(doc, presenter)).to eq("availability_section")
      end
    end
  end

  describe "#render_email_form_field" do
    let(:current_user) { OpenStruct.new(email: nil) }

    before do
      allow(helper).to receive(:current_user) { current_user }
      allow(helper).to receive(:render) { "render_email_form_field" }
    end

    context "user does not have email" do
      it "renders the email field" do
        expect(helper.render_email_form_field).to eq("render_email_form_field")
      end
    end

    context "user has email" do
      let(:current_user) { OpenStruct.new(email: "foo") }

      it "does not render the email form field" do
        expect(helper.render_email_form_field).to be_nil
      end
    end
  end

  describe "#render_electronic_notes" do
    let(:service_notes) {  { "foo" => "bar" } }
    let(:collection_notes) {  { "bizz" => "buzz" } }
    let(:config) { OpenStruct.new(
      electronic_collection_notes: service_notes,
      electronic_service_notes: collection_notes
    ) }

    before do
      allow(helper).to receive(:render) { "rendered note" }
      allow(Rails).to receive(:configuration) { config }
    end

    context "with no notes" do
      let(:field) { {} }

      it "should not render any notes" do
        expect(render_electronic_notes(field)).to be_nil
      end
    end

    context "with service notes" do
      let(:field) { { "service_id" => "bizz" } }

      it "should render the notes" do
        expect(render_electronic_notes(field)).to eq("rendered note")
      end
    end

    context "with collection notes" do
      let(:field) { { "collection_id" => "foo" } }

      it "should render the notes" do
        expect(render_electronic_notes(field)).to eq("rendered note")
      end
    end

    context "with both collection and service notes" do
      let(:field) { { "service_id" => "bizz", "collection_id" => "foo" } }

      it "should render the notes" do
        expect(render_electronic_notes(field)).to eq("rendered note")
      end
    end
  end

  describe "#electronic_resource_link_builder(field)" do
    let(:alma_domain) { "sandbox01-na.alma.exlibrisgroup.com" }
    let(:alma_institution_code) { "01TULI_INST" }

    context "only a portfolio_pid is present" do
      let(:field) { { "portfolio_id" => "12345" } }

      it "has correct link to resource" do
        expect(electronic_resource_link_builder(field)).to have_link(text: "Find it online", href: "https://sandbox01-na.alma.exlibrisgroup.com/view/uresolver/01TULI_INST/openurl?Force_direct=true&portfolio_pid=12345&rfr_id=info%3Asid%2Fprimo.exlibrisgroup.com&u.ignore_date_coverage=true")
      end

      it "does not have a separator" do
        expect(electronic_resource_link_builder(field)).to_not have_text(" - ")
      end
    end

    context "porfolio_id and title are present" do
      let(:field) { { "portfolio_id" => "77777", "title" => "Sample Name" } }

      it "displays database name if available" do
        expect(electronic_resource_link_builder(field)).to have_link(text: "Sample Name", href: "https://sandbox01-na.alma.exlibrisgroup.com/view/uresolver/01TULI_INST/openurl?Force_direct=true&portfolio_pid=77777&rfr_id=info%3Asid%2Fprimo.exlibrisgroup.com&u.ignore_date_coverage=true")
      end

      it "does not contain a separator" do
        expect(electronic_resource_link_builder(field)).to_not have_text(" - ")
      end
    end

    context "porfolio_id, title, and subtitle are present" do
      let(:field) { {
        "portfolio_id" => "77777", "title" => "Sample Name", "subtitle" => "Sample Text"
      } }

      it "displays additional information as plain text" do
        expect(electronic_resource_link_builder(field)).to have_link(text: "Sample Name", href: "https://sandbox01-na.alma.exlibrisgroup.com/view/uresolver/01TULI_INST/openurl?Force_direct=true&portfolio_pid=77777&rfr_id=info%3Asid%2Fprimo.exlibrisgroup.com&u.ignore_date_coverage=true")
        expect(electronic_resource_link_builder(field)).to have_text("Sample Text")
      end
    end

    context "item is not available" do
      let(:field) { { "availability" => "Not Available" } }

      it "skips items that are not available" do
        expect(electronic_resource_link_builder(field)).to be_nil
      end
    end
  end

  describe "#check_for_full_http_link(args)" do
    let(:alma_domain) { "sandbox01-na.alma.exlibrisgroup.com" }
    let(:alma_institution_code) { "01TULI_INST" }
    let(:args) {
        {
          document:
          {
            electronic_resource_display: [
              { "title" => "Access electronic resource.", "url" => "http://libproxy.temple.edu/login?url=http://www.aspresolver.com/aspresolver.asp?SHM2;1772483" },
              { "portfolio_id" => "77777", "title" => "Sample Name" },
            ]
          },
          field: :electronic_resource_display
        }
      }

    context "marc field links with http should use the electronic_access_links helper method" do
      it "directs an http link through the electronic_access_links method" do
        expect(check_for_full_http_link(args)).to have_link(text: "Access electronic resource", href: "http://libproxy.temple.edu/login?url=http://www.aspresolver.com/aspresolver.asp?SHM2;1772483")
      end
    end

    context "alma api links go through electronic_resource_display method" do
      it "directs an http link through the electronic_access_links method" do
        expect(check_for_full_http_link(args)).to have_link(text: "Sample Name", href: "https://sandbox01-na.alma.exlibrisgroup.com/view/uresolver/01TULI_INST/openurl?Force_direct=true&portfolio_pid=77777&rfr_id=info%3Asid%2Fprimo.exlibrisgroup.com&u.ignore_date_coverage=true")
      end
    end
  end

  describe "#electronic_access_links(field)" do
    context "with only a url" do
      let(:field) { { "url" => "http://libproxy.temple.edu/login?url=http://www.aspresolver.com/aspresolver.asp?SHM2;1772483" } }

      it "has generic message for link" do
        expect(electronic_access_links(field)).to have_link(text: "Link to Resource", href: "http://libproxy.temple.edu/login?url=http://www.aspresolver.com/aspresolver.asp?SHM2;1772483")
      end
    end

    context "with title and url" do
      let(:field) { { "title" => "Access electronic resource.", "url" => "http://libproxy.temple.edu/login?url=http://www.aspresolver.com/aspresolver.asp?SHM2;1772483" } }

      it "displays z3 subfields if available" do
        expect(electronic_access_links(field)).to have_link(text: "Access electronic resource", href: "http://libproxy.temple.edu/login?url=http://www.aspresolver.com/aspresolver.asp?SHM2;1772483")
      end
    end
  end

  describe "#subject_links(args)" do
    context "links to exact subject facet string" do
      let(:args) {
          {
            document:
            {
              subject_display: ["Middle East"]
            },
            field: :subject_display
          }
        }

      it "includes link to exact subject" do
        expect(subject_links(args).first).to have_link("Middle East", href: "#{search_catalog_path}?f[subject_facet][]=Middle+East")
      end
      it "does not link to only part of the subject" do
        expect(subject_links(args).first).to have_no_link("Middle East", href: "#{search_catalog_path}?f[subject_facet][]=Middle")
      end
    end

    context "links to subjects with special characters" do
      let(:args) {
          {
            document:
            {
              subject_display: ["Regions & Countries - Asia & the Middle East"]
            },
            field: :subject_display
          }
        }
      it "includes link to whole subject string" do
        expect(subject_links(args).first).to have_link("Regions & Countries - Asia & the Middle East", href: "#{search_catalog_path}?f[subject_facet][]=Regions+%26+Countries+-+Asia+%26+the+Middle+East")
      end
    end

    context "does not display double hyphens" do
      let(:args) {
          {
            document:
            {
              subject_display: ["Regions & Countries — —  Asia & the Middle East"]
            },
            field: :subject_display
          }
        }
      it "displays only one hyphen" do
        expect(subject_links(args).first).to have_text("Regions & Countries —  Asia & the Middle East")
      end
    end
  end

  describe "#holdings_summary_information(document)" do
    context "record has a holdings_summary field" do
      let(:document) {
          {
            "holdings_summary_display" => ["v.32,no.12-v.75,no.16 (1962-2005) Some issues missing.|22318863960003811"]
            }
        }
      it "displays the field in a human-readable format" do
        expect(helper.holdings_summary_information(document)).to eq("v.32,no.12-v.75,no.16 (1962-2005) Some issues missing.")
      end
    end

    context "record does not have a holdings_summary_display field" do
      let(:document) {
          {
            "subject_display" => ["Test"]
            }
        }
      it "does not display anything" do
        expect(helper.holdings_summary_information(document)).to be_nil
      end
    end
  end

  describe "#render_holdings_summary(document)" do
    context "record has a holdings_summary field" do
      let(:document) {
          {
            "holdings_summary_display" => ["v.32,no.12-v.75,no.16 (1962-2005) Some issues missing.|22318863960003811"]
            }
        }
      it "returns the field for display" do
        expect(render_holdings_summary(document)).to eq("<td id=\"holdings-summary\">Description: v.32,no.12-v.75,no.16 (1962-2005) Some issues missing.</td>")
      end
    end

    context "record does not have a holdings_summary_display field" do
      let(:document) {
          {
            "subject_display" => ["Test"]
            }
        }
      it "returns the default message" do
        expect(render_holdings_summary(document)).to eq("<td id=\"error-message\">We are unable to find availability information for this record. Please contact the library for more information.</td>")
      end
    end
  end

  describe "#build_holdings_summary(items, document)" do
    context "record has a holdings_summary field" do
      let(:items) do
        { "MAIN" => [Alma::BibItem.new(
          "holding_data" =>
             { "holding_id" => "22318863960003811"
           }
          )]
        }
      end
      let(:document) {
          {
            "holdings_summary_display" => ["v.32,no.12-v.75,no.16 (1962-2005) Some issues missing.|22318863960003811"]
            }
        }

      it "returns the summary for the related library" do
        expect(build_holdings_summary(items, document)).to eq("MAIN" => "v.32,no.12-v.75,no.16 (1962-2005) Some issues missing.")
      end
    end

    context "record does not have a holdings_summary_display field" do
      let(:items) do
        { "MAIN" => [Alma::BibItem.new(
          "holding_data" =>
             { "holding_id" => "22318863650003811"
           }
          )]
        }
      end

      let(:document) {
          {
            "subject_display" => []
            }
        }

      it "returns the default message" do
        expect(build_holdings_summary(items, document)).to eq("MAIN" => "")
      end
    end
  end
end
