# frozen_string_literal: true

require "rails_helper"

RSpec.describe ElectronicResourceHelper, type: :helper do
  describe "#electronic_access_links(field)" do
    context "with only a url" do
      let(:field) { { "url" => "http://libproxy.temple.edu/login?url=http://www.aspresolver.com/aspresolver.asp?SHM2;1772483" } }

      it "has generic message for link" do
        expect(electronic_access_links(field)).to have_link(text: "Link to Resource", href: "http://libproxy.temple.edu/login?url=http://www.aspresolver.com/aspresolver.asp?SHM2;1772483")
      end
    end

    context "with collection name and url" do
      let(:field) { { "title" => "Access electronic resource.", "url" => "http://libproxy.temple.edu/login?url=http://www.aspresolver.com/aspresolver.asp?SHM2;1772483" } }

      it "displays z3 subfields if available" do
        expect(electronic_access_links(field)).to have_link(text: "Access electronic resource", href: "http://libproxy.temple.edu/login?url=http://www.aspresolver.com/aspresolver.asp?SHM2;1772483")
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

    context "porfolio_id and collection name are present" do
      let(:field) { { "portfolio_id" => "77777", "title" => "Sample Name" } }

      it "displays database name if available" do
        expect(electronic_resource_link_builder(field)).to have_link(text: "Sample Name", href: "https://sandbox01-na.alma.exlibrisgroup.com/view/uresolver/01TULI_INST/openurl?Force_direct=true&portfolio_pid=77777&rfr_id=info%3Asid%2Fprimo.exlibrisgroup.com&u.ignore_date_coverage=true")
      end

      it "does not contain a separator" do
        expect(electronic_resource_link_builder(field)).to_not have_text(" - ")
      end
    end

    context "only electronic note and collection name are present" do
      let(:field) { { "portfolio_id" => "77777", "title" => "Sample Name" } }

      it "does not contain a separator" do
        allow(helper).to receive(:render_electronic_notes) { "Hello World" }
        expect(electronic_resource_link_builder(field)).to_not have_text(" - ")
      end
    end

    context "porfolio_id, collection name, and coverage statement are present" do
      let(:field) { {
        "portfolio_id" => "77777", "title" => "Sample Name", "coverage_statement" => "Sample Text"
      } }

      it "displays additional information as plain text" do
        expect(electronic_resource_link_builder(field)).to have_link(text: "Sample Text", href: "https://sandbox01-na.alma.exlibrisgroup.com/view/uresolver/01TULI_INST/openurl?Force_direct=true&portfolio_pid=77777&rfr_id=info%3Asid%2Fprimo.exlibrisgroup.com&u.ignore_date_coverage=true")
        expect(electronic_resource_link_builder(field)).to have_text("Sample Name")
      end
    end

    context "porfolio_id, collection name, and coverage statement is not present present" do
      let(:field) { {
        "portfolio_id" => "77777", "title" => "Sample Name"
      } }

      it "displays additional information as plain text" do
        expect(electronic_resource_link_builder(field)).to have_link(text: "Sample Name", href: "https://sandbox01-na.alma.exlibrisgroup.com/view/uresolver/01TULI_INST/openurl?Force_direct=true&portfolio_pid=77777&rfr_id=info%3Asid%2Fprimo.exlibrisgroup.com&u.ignore_date_coverage=true")
      end
    end

    context "item is not available" do
      let(:field) { { "availability" => "Not Available" } }

      it "skips items that are not available" do
        expect(electronic_resource_link_builder(field)).to be_nil
      end
    end
  end

  describe "#single_link_builder(field)" do
    let(:alma_domain) { "sandbox01-na.alma.exlibrisgroup.com" }
    let(:alma_institution_code) { "01TULI_INST" }

    context "with a url" do
      let(:field) { { "url" => "http://libproxy.temple.edu/login?url=http://www.aspresolver.com/aspresolver.asp?SHM2;1772483" } }

      it "single link is url" do
        expect(single_link_builder(field)).to eq("http://libproxy.temple.edu/login?url=http://www.aspresolver.com/aspresolver.asp?SHM2;1772483")
      end
    end

    context "without a url" do
      let(:field) { { "portfolio_id" => "53395029150003811" } }

      it "has generic message for link" do
        expect(single_link_builder(field)).to eq("https://sandbox01-na.alma.exlibrisgroup.com/view/uresolver/01TULI_INST/openurl?Force_direct=true&portfolio_pid=53395029150003811&rfr_id=info%3Asid%2Fprimo.exlibrisgroup.com&u.ignore_date_coverage=true")
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

    context "with authentication notes" do
      let(:field) { { "authentication_note" => "authentication note" } }

      it "should render the notes" do
        expect(render_electronic_notes(field)).to eq("rendered note")
      end

      it "should parse the authenticated notes" do
        allow(helper).to receive(:render) do |arg|
          expect(arg.dig(:locals, :authentication_notes)).to eq("authentication note")
          ""
        end

        render_electronic_notes(field)
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
end
