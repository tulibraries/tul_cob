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

    context "document does not contain an isbn" do
      let(:document) { {} }
      it "does not return the data-isbn string" do
        expect(isbn_data_attribute(document)).to be_nil
      end
    end
  end

  describe "#lccn_data_attribute" do
    context "document contains an lccn" do
      let(:document) { { lccn_display: ["sn#00061556"] } }
      it "returns the data-lccn string" do
        expect(lccn_data_attribute(document)).to eql "data-lccn=sn#00061556"
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
    let(:user) { FactoryBot.build(:user) }
    let(:doc) { SolrDocument.new(purchase_order: true, id: "foo") }
    let(:can_purchase_order?) { true }
    let(:config) { CatalogController.blacklight_config }
    let(:context) { Blacklight::Configuration::Context.new(config) }
    let(:presenter) { helper.index_presenter(doc) }

    before(:each) do
      allow(helper).to receive(:link_to) { "render_login_link" }
      allow(helper).to receive(:current_user) { user }
      allow(helper).to receive(:content_tag) {}
      allow(helper).to receive(:render) {}
      allow(user).to receive(:can_purchase_order?) { can_purchase_order? }

      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config) { config }
        allow(helper).to receive(:blacklight_configuration_context) { context }
      end

      helper.render_purchase_order_availability(presenter)
    end

    context "document has purchase order and user is not logged in" do
      let(:user) { nil }

      it "should render the log_in link" do
        expect(helper).to have_received(:render).with(
          partial: "purchase_order_anonymous_button",
          locals: { document: doc, link: "render_login_link" }
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
          :div, "render_login_link", class: "requests-container mb-2 ml-0"
        )
      end
    end

    context "document has purchase order but user cannot purchase order" do
      let(:can_purchase_order?) { false }

      it "should render purchase allow message" do
        expect(helper).to have_received(:content_tag).with(
          :div, t("purchase_order_allowed"), class: "availability border border-header-grey"
        )
      end
    end

    context "document does not have purchase order button" do
      let(:doc) { SolrDocument.new(purchase_order: false) }

      it "should not render the purchase_order_button" do
        expect(helper.render_purchase_order_availability(presenter)).to be_nil
      end
    end
  end

  describe "#render_purchase_order_show_link" do
    let(:args) { { document: SolrDocument.new(purchase_order: true, id: "foo") } }
    let(:user) { FactoryBot.build_stubbed(:user) }
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

  describe "#render_alma_availability(document)" do
    let(:doc) { SolrDocument.new(bound_with_ids: ["foo"]) }
    let(:config) { CatalogController.blacklight_config }

    before do
      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config) { config }
      end
    end

    context "with bound_with_ids defined" do
      it "renders the bound_with_ids" do
        expect(helper.render_alma_availability(doc)).not_to be_nil
      end
    end

    context "with no bound with ids available" do
      let(:doc) { SolrDocument.new(bound_with_ids: nil) }

      it "does not render the bound_with_ids" do
        expect(helper.render_alma_availability(doc)).to be_nil
      end
    end

    context "without bound_with_ids configured" do
      let(:config) { PrimoCentralController.blacklight_config }

      it "does not render the bound_with_ids" do
        expect(helper.render_alma_availability(doc)).to be_nil
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

  describe "#get_unavailable_notes" do
    let(:service_notes) {  { "foo" => { "value" => "foo" } } }

    before do
      allow(helper).to receive(:electronic_notes).with("service") { service_notes }
    end

    context "with no unavailable notes" do
      it "should not return any unavailability notes" do
        expect(helper.get_unavailable_notes("bizz")).to eq([])
      end
    end

    context "with unavailable notes" do
      let(:service_notes) {  { "bizz" => {
        "key" => "foo",
        "service_temporarily_unavailable" => "foo",
        "service_unavailable_reason" => "bar",
        "service_unavailable_date" => "buzz",
      } } }

      it "should not return any unavailability notes" do
        expect(helper.get_unavailable_notes("bizz")).to eq(["This service is temporarily unavailable due to: bar."])
      end
    end
  end

  describe "#render_electronic_notes" do
    let(:service_notes) {  { "foo" => { "value" => "foo" } } }
    let(:collection_notes) {  { "bizz" => { "value" => "bar" } } }
    let(:public_notes) { "public note" }

    before do
      allow(helper).to receive(:render) { "rendered note" }
      allow(Rails.cache).to receive(:fetch).with("collection_notes") { collection_notes }
      allow(Rails.cache).to receive(:fetch).with("service_notes") { service_notes }
    end

    context "with no notes" do
      let(:field) { {} }

      it "should not render any notes" do
        expect(render_electronic_notes(field)).to be_nil
      end
    end

    context "with public notes" do
      let(:field) { { "public_note" => "public note" } }

      it "should render the notes" do
        expect(render_electronic_notes(field)).to eq("rendered note")
      end
    end

    context "with service notes" do
      let(:field) { { "service_id" => "foo" } }

      it "should render the notes" do
        expect(render_electronic_notes(field)).to eq("rendered note")
      end
    end

    context "with collection notes" do
      let(:field) { { "collection_id" => "bizz" } }

      it "should render the notes" do
        expect(render_electronic_notes(field)).to eq("rendered note")
      end
    end

    context "with both collection and service notes" do
      let(:field) { { "service_id" => "foo", "collection_id" => "bizz" } }

      it "should render the notes" do
        expect(render_electronic_notes(field)).to eq("rendered note")
      end
    end

    context "with unavailable notes" do
      let(:field) { { "service_id" => "buzz", "collection_id" => "bizz" } }
      let(:service_notes) { { "foo" => {
        "service_temporarily_unavailable" => "foo",
        "service_unavailable_date" => "bar",
        "service_unavailable_reason" => "buzz"
      } } }

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

  describe "#genre_links" do
    context "duplicate genres" do
      let(:args) {
          {
            document:
            {
              genre_display: [ "foo", "foo", "bar" ]
            },
            field: :genre_display
          }
        }

      it "filters out duplicate genres" do
        expect(genre_links(args).count).to eq(2)
      end
    end
  end

  describe "#subject_links(args)" do
    let(:base_path) { "foo" }

    before do
      allow(helper).to receive(:base_path) { base_path }
    end

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
        expect(subject_links(args).first).to have_link("Middle East", href: "#{base_path}?f[subject_facet][]=Middle+East")
      end
      it "does not link to only part of the subject" do
        expect(subject_links(args).first).to have_no_link("Middle East", href: "#{base_path}?f[subject_facet][]=Middle")
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
        expect(subject_links(args).first).to have_link("Regions & Countries - Asia & the Middle East", href: "#{base_path}?f[subject_facet][]=Regions+%26+Countries+-+Asia+%26+the+Middle+East")
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

    context "duplicate entry" do
      let(:args) {
          {
            document:
            {
              subject_display: [
                "Regions & Countries — —  Asia & the Middle East",
                "Regions & Countries — —  Asia & the Middle East",
              ]
            },
            field: :subject_display
          }
        }

      it "filters out duplicates" do
        expect(subject_links(args).count).to eq(1)
      end
    end
  end

  describe "#database_links(args)" do
    let(:base_path) { "foo" }

    before do
      allow(helper).to receive(:base_path) { base_path }
    end

    context "links to database type facet" do
      let(:args) {
          {
            document:
            {
              az_format: ["eBooks"]
            },
            field: :az_format
          }
        }

      it "includes link to database type" do
        expect(database_type_links(args).first).to have_link("eBooks", href: "#{base_path}?f[az_format][]=eBooks")
      end
    end
  end

  describe "#database_subject_links(args)" do
    let(:base_path) { "foo" }

    before do
      allow(helper).to receive(:base_path) { base_path }
    end

    context "links to database type facet" do
      let(:args) {
          {
            document:
            {
              az_subject_facet: ["art"]
            },
            field: :az_subject_facet
          }
        }

      it "includes link to database type" do
        expect(database_subject_links(args).first).to have_link("art", href: "#{base_path}?f[az_subject_facet][]=art")
      end
    end
  end

  describe "#ez_borrow_list_item(controller_name)" do
    context "catalog controller" do
      let(:controller_name) { "catalog" }
      it "adds an ez_borrow list item" do
        expect(ez_borrow_list_item(controller_name)).to eql "<li>To request books that are not available at Temple, use <a target=\"_blank\" href=\"https://ezb.relaisd2d.com/?LS=TEMPLE\">E-ZBorrow</a>.</li>"
      end
    end

    context "journal controller" do
      let(:controller_name) { "journal" }
      it "does not add an ez_borrow list item" do
        expect(ez_borrow_list_item(controller_name)).to be_nil
      end
    end
  end

  describe "solr_field_to_s(document, field)" do
    let(:string) { helper.solr_field_to_s(document, field) }
    let(:field) { "test" }
    let(:document) {  { "#{field}" => value } }
    context "the field value is empty" do
      let(:value) { "" }
      it "returns an empty string" do
        expect(string).to eql ""
      end
    end
    context "the field value is nil" do
      let(:value) { nil }
      it "returns an empty string" do
        expect(string).to eql ""
      end
    end
    context "the field value is non empty string value" do
      let(:value) { "an id" }
      it "returns an empty string" do
        expect(string).to eql "an id"
      end
    end

    context "the field value is an empty array" do
      let(:value) { [] }
      it "returns an empty string" do
        expect(string).to eql ""
      end
    end

    context "the field value is an array with a single string value" do
      let(:value) { ["one value"] }
      it "returns an empty string" do
        expect(string).to eql "one value"
      end
    end

    context "the field value is an array with a single integer value" do
      let(:value) { [3] }
      it "returns an empty string" do
        expect(string).to eql "3"
      end
    end
    context "the field value is an array with a single integer value" do
      let(:value) { [3] }
      it "returns an empty string" do
        expect(string).to eql "3"
      end
    end
    context "the field value is an array multiple string values" do
      let(:value) { ["one", "two"] }
      it "returns an empty string" do
        expect(string).to eql "one, two"
      end
    end
  end

  describe "#_build_libwizard_url(document)" do
    let(:base_url) { "https://temple.libwizard.com/f/LibrarySearchRequest?" }
    let(:constructed_url) { helper._build_libwizard_url(document) }
    context "document is missing all data" do
      let(:document) { {} }
      it "returns a url with no params" do
        expect(constructed_url).to eq base_url
      end
    end
    context "when mappable fields are present" do
      let(:document) {
        {
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
        }
      }
      it "maps the expected parameters" do
        expect(constructed_url).to include("rft.title=title")
        expect(constructed_url).to include("rft.date=2020")
        expect(constructed_url).to include("edition=1st+edition")
        expect(constructed_url).to include("rft_id=https%3A%2F%2Flibrarysearch.temple.edu%2Fcatalog%2FbestIDever")
        expect(constructed_url).to include("rft.isbn=12345678")
        expect(constructed_url).to include("rft.issn=4567890123%2C+9087654321")
        expect(constructed_url).to include("rft.oclcnum=98765432")
        expect(constructed_url).to include("rft.pub=imprint_display_1%2C+imprint_display_2%2C+imprint_prod_display%2C+imprint_dist_display%2C+imprint_man_display")
      end
    end
  end

  describe "#digital_help_allowed?(document)" do
    context "is not a physical item" do
      let(:document) { { "availability_facet" => "Online" } }
      it "returns false" do
        expect(digital_help_allowed?(document)).to be false
      end
    end
    context "is a physical item" do
      let(:document) { { "availability_facet" => "At the Library" } }
      it "returns true" do
        expect(digital_help_allowed?(document)).to be true
      end
    end
    context "is an object" do
      let(:document) { { "format" => "Object" } }
      it "returns false" do
        expect(digital_help_allowed?(document)).to be false
      end
    end
    context "is a physical item and an online item" do
      let(:document) { {
        "availability_facet" => "At the Library",
        "electronic_resource_display" => "foo"
         } }
      it "returns false" do
        expect(digital_help_allowed?(document)).to be false
      end
    end
    context "is a physical item with hathitrust link" do
      let(:document) { {
        "availability_facet" => "At the Library",
        "hathi_trust_bib_key_display" => "foo"
         } }
      it "returns nil" do
        expect(digital_help_allowed?(document)).to be false
      end
    end
  end

  describe "#open_shelves_allowed?(document)" do
    context "is not in a relevant library" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "LAW",
        "permanent_location" => "reference",
        "current_library" => "LAW",
        "current_location" => "reference",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811" }]
          }
        }

      it "returns false" do
        expect(open_shelves_allowed?(document)).to be false
      end
    end

    context "is in a relevant Charles location" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "MAIN",
        "permanent_location" => "juvenile",
        "current_library" => "MAIN",
        "current_location" => "juvenile" }]
          }
        }
      it "returns true" do
        expect(open_shelves_allowed?(document)).to be true
      end
    end

    context "is in a relevant Ambler location" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "AMBLER",
        "permanent_location" => "stacks",
        "current_library" => "AMBLER",
        "current_location" => "stacks" }]
          }
        }
      it "returns true" do
        expect(open_shelves_allowed?(document)).to be true
      end
    end

    context "is in a relevant library, but not location" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "MAIN",
        "permanent_location" => "Reference",
        "current_library" => "MAIN",
        "current_location" => "reference" }]
          }
        }
      it "returns false" do
        expect(open_shelves_allowed?(document)).to be false
      end
    end

    context "is in a relevant location, but not library" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23433968230003811",
        "item_policy" => "0",
        "permanent_library" => "JAPAN",
        "permanent_location" => "stacks",
        "current_library" => "JAPAN",
        "current_location" => "stacks" },
        { "item_pid" => "23311482710003811",
        "item_policy" => "2",
        "permanent_library" => "MAIN",
        "permanent_location" => "serials",
        "current_library" => "MAIN",
        "current_location" => "serials" }]
          }
        }
      it "returns false" do
        expect(open_shelves_allowed?(document)).to be false
      end
    end
  end

  describe "#build_hathitrust_url(field)" do
    let(:field) { { "bib_key" => "000005117", "access" => "allow" } }
    let(:base_url) { "https://catalog.hathitrust.org/Record/000005117?signon=swle:https://fim.temple.edu/idp/shibboleth" }
    let(:constructed_url) { helper.build_hathitrust_url(field) }

    it "returns a correctly formed url" do
      expect(constructed_url).to eq base_url
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

  describe "#campus_closed?" do
    before do
      allow(helper).to receive(:params) { params }
    end

    context "params campus_closed is not set" do
      let(:params) { {} }

      it "returns false with an empty params object method" do
        expect(campus_closed?).to be(false)
      end
    end

    context "params campus_closed is true" do
      let(:params) { { "campus_closed" => "true" } }

      it "returns true when campus_closed param is not 'false'" do
        expect(campus_closed?).to be(true)
      end
    end

    context "params campus_closed is false" do
      let(:params) { { "campus_closed" => "false" } }

      it "returns false with an empty params object method" do
        expect(campus_closed?).to be(false)
      end
    end
  end

  describe "#derived_lib_guides_search_term(solr_response)" do
    before do
      allow(helper).to receive(:params) { params }
      allow(self).to receive(:_subject_topic_facet_terms).and_return(["wu tang", "clan aint"])
    end
    let(:params) { { "q" => "thing" } }

    it "returns the origial search term and subject topics in parenthesis and combined with OR " do
      expect(derived_lib_guides_search_term(nil)).to eq("(thing) OR (wu tang) OR (clan aint)")
    end
  end

  describe "#_subject_topic_facet_terms(response)" do
    let(:subject) { _subject_topic_facet_terms(response) }
    let(:solr_response) { Blacklight::Solr::Response.new({ responseHeader: {}, facet_counts: { facet_fields: [facet_field] } }, {}) }
    let(:facet_field) { ["wrong", []] }

    context "nil response" do
      let(:response) { nil }
      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "empty solr response" do
      let(:response) { solr_response }
      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "solr_response without subject_topic_facet" do
      let(:response) { solr_response }
      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "solr_response with subject_topic_facet" do
      let(:facet_field) { ["subject_topic_facet", ["foo", 1]] }
      let(:response) { solr_response }
      it "returns an empty array" do
        expect(subject).to eq(["foo"])
      end
    end

    context "solr_response with subject_topic_facet multiple values" do
      let(:facet_field) { ["subject_topic_facet", ["foo", 1, "boo", 2]] }
      let(:response) { solr_response }
      it "returns an empty array" do
        expect(subject).to eq(["foo", "boo"])
      end
    end
  end
end
