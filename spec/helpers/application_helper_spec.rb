# frozen_string_literal: true

require "rails_helper"

# Specs in this file have access to a helper object that includes
# the ApplicationHelper. For example:
#
# describe ApplicationHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe ApplicationHelper, type: :helper do
  describe "#electronic_resource_link_builder(field)" do
    let(:alma_domain) { "sandbox01-na.alma.exlibrisgroup.com" }
    let(:alma_institution_code) { "01TULI_INST" }

    context "only a portfolio_pid is present" do
      let(:field) { "12345" }

      it "has correct link to resource" do
        expect(electronic_resource_link_builder(field)).to have_link(text: "Find it online", href: "https://sandbox01-na.alma.exlibrisgroup.com/view/uresolver/01TULI_INST/openurl?Force_direct=true&portfolio_pid=12345&rfr_id=info%3Asid%2Fprimo.exlibrisgroup.com&u.ignore_date_coverage=true")
      end

      it "does not have a separator" do
        expect(electronic_resource_link_builder(field)).to_not have_text(" - ")
      end
    end

    context "two subfields present" do
      let(:field) { "77777|Sample Name" }

      it "displays database name if available" do
        expect(electronic_resource_link_builder(field)).to have_link(text: "Sample Name", href: "https://sandbox01-na.alma.exlibrisgroup.com/view/uresolver/01TULI_INST/openurl?Force_direct=true&portfolio_pid=77777&rfr_id=info%3Asid%2Fprimo.exlibrisgroup.com&u.ignore_date_coverage=true")
      end

      it "does not contain a separator" do
        expect(electronic_resource_link_builder(field)).to_not have_text(" - ")
      end
    end

    context "three subfields present" do
      let(:field) { "77777|Sample Name|Sample Text" }

      it "displays additional information as plain text" do
        expect(electronic_resource_link_builder(field)).to have_link(text: "Sample Name", href: "https://sandbox01-na.alma.exlibrisgroup.com/view/uresolver/01TULI_INST/openurl?Force_direct=true&portfolio_pid=77777&rfr_id=info%3Asid%2Fprimo.exlibrisgroup.com&u.ignore_date_coverage=true")
        expect(electronic_resource_link_builder(field)).to have_text("Sample Text")
      end
    end

    context "item is not available" do
      let(:field) { "|||Not Available" }
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
            electronic_resource_display: ["Access electronic resource. |http://libproxy.temple.edu/login?url=http://www.aspresolver.com/aspresolver.asp?SHM2;1772483", "77777|Sample Name"]
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
    context "only a url is present" do
      let(:field) { "Link to Resource |http://libproxy.temple.edu/login?url=http://www.aspresolver.com/aspresolver.asp?SHM2;1772483" }

      it "has generic message for link" do
        expect(electronic_access_links(field)).to have_link(text: "Link to Resource", href: "http://libproxy.temple.edu/login?url=http://www.aspresolver.com/aspresolver.asp?SHM2;1772483")
      end
    end

    context "multiple subfields present" do
      let(:field) { "Access electronic resource. |http://libproxy.temple.edu/login?url=http://www.aspresolver.com/aspresolver.asp?SHM2;1772483" }

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
  end

  describe "#render_nav_link" do
    let(:current_search_session) { OpenStruct.new(query_params: {}) }
    let(:request) { OpenStruct.new(original_fullpath: "/") }

    before(:each) do
      allow(helper).to receive(:request) { request }
      without_partial_double_verification do
        allow(helper).to receive(:current_search_session) { current_search_session }
      end
    end

    context "path not current page" do
      it "renders a link without the active class" do
        link = "<li class=\"nav-btn header-links\"><a class=\"nav-link\" href=\"/catalog\">More</a></li>"
        expect(helper.render_nav_link(:search_catalog_path, "More")).to eq(link)
      end
    end

    context "path is current page" do
      let(:request) { OpenStruct.new(original_fullpath: "/catalog") }
      it "renders a link with the active class" do
        link = "<li class=\"nav-btn header-links active\"><a class=\"nav-link active\" href=\"/catalog\">More</a></li>"
        expect(helper.render_nav_link(:search_catalog_path, "More")).to eq(link)
      end
    end

    context "path contains a query" do
      let(:current_search_session) { OpenStruct.new(query_params: { q: "foo" }) }

      it "gets the query added to the generated link" do
        link = "<li class=\"nav-btn header-links\"><a class=\"nav-link\" href=\"/catalog?q=foo\">More</a></li>"
        expect(helper.render_nav_link(:search_catalog_path, "More")).to eq(link)
      end
    end
  end

  describe "#is_active?(path)" do
    let(:current_page?) { true }
    let(:request) { OpenStruct.new(original_fullpath: "/") }

    before do
      allow(helper).to receive(:request) { request }
      allow(helper).to receive(:current_page?) { current_page? }
    end

    context "current page is :everything_path path and orig path is /" do
      it "is active" do
        expect(helper.is_active?(:everything_path)).to be_truthy
      end
    end

    context "current page is :search_books_path and orig path is /books/foobar"  do
      let(:current_page?) { false }
      let(:request) { OpenStruct.new(original_fullpath: "/books/foobar") }

      it "is active" do
        expect(helper.is_active?(:search_books_path)).to be_truthy
      end
    end

    context ":search_books_path does not match beginning of current page" do
      let(:current_page?) { false }
      let(:request) { OpenStruct.new(original_fullpath: "/articles/foobar") }

      it "is not active" do
        expect(helper.is_active?(:search_books_path)).to be_falsey
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

  describe "#display_holdings_summary_without_default_message(document)" do
    context "record has a holdings_summary field" do
      let(:document) {
          {
            "holdings_summary_display" => ["v.32,no.12-v.75,no.16 (1962-2005) Some issues missing.|22318863960003811"]
            }
        }
      it "returns the field for display" do
        expect(display_holdings_summary_without_default_message(document)).to eq("<td id=\"holdings-summary\">Description: v.32,no.12-v.75,no.16 (1962-2005) Some issues missing.</td>")
      end
    end

    context "record does not have a holdings_summary_display field" do
      let(:document) {
          {
            "subject_display" => ["Test"]
            }
        }
      it "returns the default message" do
        expect(helper.display_holdings_summary_without_default_message(document)).to eq("<td id=\"error-message\">We are unable to find availability information for this record. Please contact the library for more information.</td>")
      end
    end
  end

  describe "#display_holdings_summary(items, document)" do
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
        expect(display_holdings_summary(items, document)).to eq("MAIN" => "v.32,no.12-v.75,no.16 (1962-2005) Some issues missing.")
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
        expect(helper.display_holdings_summary(items, document)).to eq("MAIN" => "")
      end
    end
  end
end
