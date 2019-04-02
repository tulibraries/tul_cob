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
    let(:response) { Blacklight::Solr::Response.new(nil, nil) }

    before(:each) {
      helper.instance_variable_set(:@document, doc)
      helper.instance_variable_set(:@response, response)
      allow(helper).to receive(:render) {}
      helper.render_marc_view
    }

    context "document responds to to_marc" do
      it "renders the marc_view template" do
        expect(helper).to have_received(:render).with("marc_view", document: nil)
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

  describe "#render_purchase_order_availability" do
    let(:args) { { document: SolrDocument.new(purchase_order: true, id: "foo") } }
    let(:user) { FactoryBot.build(:user) }
    let(:can_purchase_order?) { true }

    before(:each) do
      allow(helper).to receive(:link_to) { "render_login_link" }
      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:content_tag) {}
      allow(helper).to receive(:render) {}
      allow(user).to receive(:can_purchase_order?) { can_purchase_order? }

      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config) { blacklight_config }
      end

      helper.render_purchase_order_availability(args)
    end

    context "document has purchase order and user is not logged in" do
      let(:user) { nil }

      it "should render the log_in link" do
        expect(helper).to have_received(:render).with(
          partial: "purchase_order_anonymous_button",
          locals: { document: args[:document], link: "" }
        )
      end
    end

    context "document has purchase order and user is not logged in and link configured to appear in button" do
      let(:user) { nil }
      let(:args) { {
        document: SolrDocument.new(purchase_order: true, id: "foo"),
        config: { with_po_link: true },
      } }

      it "should render the log_in link inside of button" do
        expect(helper).to have_received(:render).with(
          partial: "purchase_order_anonymous_button",
          locals: { document: args[:document], link: "render_login_link" }
        )
      end
    end

    context "document has purchase order and user is logged in" do
      it "should render the purchase order button" do
        expect(helper).to have_received(:content_tag).with(
          :div, "render_login_link", class: "requests-container"
        )
      end
    end

    context "document has purchase order but user cannot purchase order" do
      let(:can_purchase_order?) { false }

      it "should render purchase allow message" do
        expect(helper).to have_received(:content_tag).with(
          :div, t("purchase_order_allowed"), class: "availability"
        )
      end
    end

    context "document does not have purchase order button" do
      let(:args) { { document: SolrDocument.new(purchase_order: false) } }

      it "should not render the purchase_order_button" do
        expect(helper.render_purchase_order_availability(args)).to be_nil
      end
    end
  end

  describe "#render_purchase_order_show_link" do
    let(:args) { { document: SolrDocument.new(purchase_order: true, id: "foo") } }
    let(:user) { FactoryBot.create(:user) }
    let(:can_purchase_order?) { true }

    before(:each) do
      allow(helper).to receive(:link_to) { "render_login_link" }
      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:render_purchase_order_button) { "render_purchase_order_button" }
      allow(user).to receive(:can_purchase_order?) { can_purchase_order? }

      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config) { blacklight_config }
      end

      helper.render_purchase_order_show_link(args)
    end

    context "document has purchase order and user is not logged in" do
      let(:user) { nil }

      it "should render the log in in link" do
        expect(helper.render_purchase_order_show_link(args)).to eq("render_login_link")
      end
    end

    context "document does not have purchase order" do
      let(:args) { { document: SolrDocument.new(purchase_order: false, id: "foo") } }

      it "should not render the log in in link" do
        expect(helper.render_purchase_order_show_link(args)).to be_nil
      end
    end

    context "user is logged in and cannot purchase an order" do
      let(:can_purchase_order?) { false }

      it "should not render the log in in link" do
        expect(helper.render_purchase_order_show_link(args)).to be_nil
      end
    end

    context "user is logged in and can purchase an order" do
      it "should not render the log in in link" do
        expect(helper.render_purchase_order_show_link(args)).to eq("render_purchase_order_button")
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

    context "only electronic note and title are present" do
      let(:field) { { "portfolio_id" => "77777", "title" => "Sample Name" } }

      it "does not contain a separator" do
        allow(helper).to receive(:render_electronic_notes) { "Hello World" }
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
end
