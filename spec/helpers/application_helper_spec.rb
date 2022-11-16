# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
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
        expect(helper.render_nav_link(:search_catalog_path, "More")).to have_link("More", href: "/catalog")
        expect(helper.render_nav_link(:search_catalog_path, "More")).to_not have_css(".active")
      end
    end

    context "path is current page" do
      let(:request) { OpenStruct.new(original_fullpath: "/catalog") }
      it "renders a link with the active class" do
        expect(helper.render_nav_link(:search_catalog_path, "More")).to have_link("More", href: "/catalog")
        expect(helper.render_nav_link(:search_catalog_path, "More")).to have_css(".active")
      end
    end

    context "path contains a query" do
      let(:current_search_session) { OpenStruct.new(query_params: { q: "foo" }) }

      it "gets the query added to the generated link" do
        expect(helper.render_nav_link(:search_catalog_path, "More")).to have_link("More", href: "/catalog?q=foo")
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

    context "current page is :search_journals_path and orig path is /journals/foobar"  do
      let(:current_page?) { false }
      let(:request) { OpenStruct.new(original_fullpath: "/journals/foobar") }

      it "is active" do
        expect(helper.is_active?(:search_journals_path)).to be_truthy
      end
    end

    context ":search_journals_path does not match beginning of current page" do
      let(:current_page?) { false }
      let(:request) { OpenStruct.new(original_fullpath: "/articles/foobar") }

      it "is not active" do
        expect(helper.is_active?(:search_journals_path)).to be_falsey
      end
    end
  end

  describe "#citation_labels(format)" do
    context "citation format is APA" do
      let(:format) { "APA" }
      it "displays APA" do
        expect(citation_labels(format)).to eq("APA (6th)")
      end
    end

    context "citation format is CHICAGO" do
      let(:format) { "CHICAGO" }
      it "displays APA" do
        expect(citation_labels(format)).to eq("Chicago Author-Date (15th)")
      end
    end
  end

  describe "#aeon_request_allowed(document)" do
    context "item is at SCRC" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "SCRC",
        "permanent_location" => "rarestacks",
        "current_library" => "SCRC",
        "current_location" => "rarestacks",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811" }]
          }
        }

      it "returns true" do
        expect(helper.aeon_request_allowed(document)).to be true
      end
    end

    context "item is at SCRC" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "MAIN",
        "permanent_location" => "stacks",
        "current_library" => "MAIN",
        "current_location" => "rarestacks",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811" }]
          }
        }

      it "returns true" do
        expect(helper.aeon_request_allowed(document)).to be false
      end
    end
  end

  describe "#aeon_request_button(document)" do
    context "item is at SCRC" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "SCRC",
        "permanent_location" => "rarestacks",
        "current_library" => "SCRC",
        "current_location" => "rarestacks",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811" }]
          }
        }

      it "display the aeon request button" do
        expect(helper.aeon_request_button(document)).to have_button("Go to SCRC Researcher Account")
      end
    end

    context "item is NOT at SCRC" do
      let(:document) { { "items_json_display" =>
        [{ "item_pid" => "23237957740003811",
        "item_policy" => "5",
        "permanent_library" => "MAIN",
        "permanent_location" => "stacks",
        "current_library" => "Main",
        "current_location" => "stacks",
        "call_number" => "DVD 13 A165",
        "holding_id" => "22237957750003811" }]
          }
        }

      it "display the aeon request button" do
        expect(helper.aeon_request_button(document)).to_not have_button("Go to SCRC Researcher Account")
      end
    end
  end

  describe "#emergency_alert_message" do
    context "for_header is false" do
      it "does return the scroll_text" do
        helper.instance_variable_set("@manifold_alerts_thread", get_manifold_alerts)
        expect(helper.emergency_alert_message).to eq("Test banner message")
      end
    end
  end

  describe "#emergency_alert_link" do
    context "link field is present" do
      it "does return the link" do
        helper.instance_variable_set("@manifold_alerts_thread", get_manifold_alerts)
        expect(helper.emergency_alert_link).to have_text("Click here to see full details.")
      end
    end
  end

  describe "#manifold_alerts" do
    context "[] value" do
      it "returns empty array []" do
        helper.instance_variable_set("@manifold_alerts_thread", Thread.new { [] })
        expect(helper.manifold_alerts).to eq([])
      end
    end

    context "spec/fixtures/emergency_alert.json" do
      it "filters out for_header alerts" do
        helper.instance_variable_set("@manifold_alerts_thread", get_manifold_alerts)

        expect(helper.manifold_alerts.count).to eq(1)
        expect(helper.manifold_alerts.first.dig("attributes", "for_header")).to eq(false)
      end
    end
  end

  def get_manifold_alerts
    ApplicationController.new.get_manifold_alerts
  end

  describe "#query_list" do
    let(:params) { ActionController::Parameters.new query_list: "true" }

    before do
      allow(helper).to receive(:params) { params }
    end

    context "title and query provided" do
      it "sets data-controller=\"query-list\" div" do
        expect(helper.query_list("foo", "tooltip", "q=bar")).to match(/<div.* data-controller="query-list".*>/)
      end

      it "sets data-query-list-url" do
        expect(helper.query_list("foo", "tooltip", "q=bar")).to match(/<div.* data-controller="query-list".*data-query-list-url="\/query_list\?q=bar&amp;per_page=5".*>/)
      end

      it "sets tile to link 'foo' that links back to the query" do
        expect(helper.query_list("foo", "tooltip", "q=bar")).to match(/<h.*><a href="\/catalog\?q=bar">foo<\/a><\/h.*>/)
      end

      it "sets a target div called data-target=\"query-list.results\"" do
        expect(helper.query_list("foo", "tooltip", "q=bar")).to match(/<div.*data-query-list-target="results".*>/)
      end
    end

    context "@document.id is available" do
      # This only happens in a record view context.
      it "adds the filer_id query param" do
        helper.instance_variable_set("@document", SolrDocument.new(id: "fizz"))
        expect(helper.query_list("foo", "tooltip", "q=bar")).to match(/filter_id=fizz/)
      end
    end

    context "@document.id is NOT available" do
      it "does NOT add the filer_id query param" do
        expect(helper.query_list("foo", "tooltip", "q=bar")).not_to match(/filter_id=fizz/)
      end
    end

    context "footer_field is passed" do
      it "adds a footer_field query param" do
        expect(helper.query_list("foo", "tooltip", query = "q=bar", footer_field = "buzz")).to match(/footer_field=buzz/)
      end
    end
  end

  describe "#query_list_footer_value" do
    let(:value) { helper.query_list_footer_value(document, footer_field) }

    context "field not present in documeent" do
      let(:footer_field) { "some_rando_field" }
      let(:document) { SolrDocument.new({}) }

      it "returns nil"  do
        expect(value).to be_nil
      end
    end

    context "field present in doc" do
      let(:footer_field) { "some_rando_field" }
      let(:document) { SolrDocument.new({ "some_rando_field" => ["foo"] }) }

      it "returns first value by default"  do
        expect(value).to eq("foo")
      end
    end

    context "field is date_added_facet" do
      let(:footer_field) { "date_added_facet" }
      let(:document) { SolrDocument.new({ "date_added_facet" => [17760704] }) }

      it "parses the first date it finds and formats it"  do
        expect(value).to eq("1776-07-04")
      end
    end

    context "field is date_added_facet containing a 0 in the array" do
      let(:footer_field) { "date_added_facet" }
      let(:document) { SolrDocument.new({ "date_added_facet" => [0, 20220914] }) }

      it "removes the 0 from the array and parses date"  do
        expect(value).to eq("2022-09-14")
      end
    end

    context "field is date_added_facet but date cannot be parsed" do
      let(:footer_field) { "date_added_facet" }
      let(:document) { SolrDocument.new({ "date_added_facet" => [20211905] }) }


      it "return an empty string and post a HoneyBadger error"  do
        expect { helper.query_list_footer_value(document, footer_field) }.to_not raise_error
        expect(value).to eq("")

        notices = Honeybadger::Backend::Test.notifications[:notices]
        error_message = notices.first.error_message
        expect(error_message).to eq("Error trying to parse date_added_facet value; @htomren invalid date")
      end
    end

    context "lc_call_number_display and present" do
      let(:footer_field) { "lc_call_number_display" }
      let(:document) { SolrDocument.new({ "lc_call_number_display" => ["foo"] }) }

      it "returns the value" do
        expect(value).to eq("foo")
      end
    end

    context "lc_call_number_display and NOT present" do
      let(:footer_field) { "lc_call_number_display" }
      let(:document) { SolrDocument.new({}) }

      it "returns nil" do
        expect(value).to be_nil
      end
    end
  end

  describe "#creator_query_list(document)" do
    let(:params) { ActionController::Parameters.new query_list: "true" }

    before do
      allow(helper).to receive(:params) { params }
    end

    context "single creator provided" do
      let(:document) { { "creator_display" => ["Caroli, Sergio"] } }

      it "generates a query_list for the listed creator" do
        expect(helper.creator_query_list(document)).to include("query_list?f[creator_facet][]=Caroli, Sergio")
      end
    end

    context "single creator provided with additional piped information" do
      let(:document) { { "creator_display" => ["Hayes, Declan|author"] } }

      it "generates a query_list for the listed creator without info after pipe" do
        expect(helper.creator_query_list(document)).to include("query_list?f[creator_facet][]=Hayes, Declan")
        expect(helper.creator_query_list(document)).to_not include("query_list?f[creator_facet][]=author")
      end
    end

    context "multiple creators provided" do
      let(:document) { { "creator_display" => [
        "Caroli, Sergio",
        "Mackay, Alan L. (Alan Lindsay), 1926-"
        ] } }

      it "generates a query_list for only the first listed creator" do
        expect(helper.creator_query_list(document)).to include("query_list?f[creator_facet][]=Caroli, Sergio")
        expect(helper.creator_query_list(document)).to_not include("query_list?f[creator_facet][]=Mackay, Alan L")
      end
    end

    context "no creator provided" do
      let(:document) { { "creator_display" => [""] } }

      it "does not genearte a query list" do
        expect(helper.creator_query_list(document)).to be_nil
      end
    end
  end

  describe "#call_number_query_list(document)" do
    let(:params) { ActionController::Parameters.new query_list: "true" }

    before do
      allow(helper).to receive(:params) { params }
    end

    context "single call_number provided" do
      let(:document) { { "lc_call_number_display" => ["DS891.2.H392013"] } }

      it "generates a query_list for the call number in ascending order" do
        expect(helper.call_number_query_list(document)).to include("DS891.2.H392013")
        expect(helper.call_number_query_list(document)).to include("lc_call_number_sort+asc")
        expect(helper.call_number_query_list(document)).to include("range%5Blc_classification%5D%5Bbegin")
      end
    end

    context "single call_number provided with desc order variable passed in" do
      let(:document) { { "lc_call_number_display" => ["DS835 .J37 2015"] } }
      let(:order) { "desc" }

      it "generates a query_list for the call number in descending order" do
        expect(helper.call_number_query_list(document, order)).to include("DS835.J372015")
        expect(helper.call_number_query_list(document, order)).to include("lc_call_number_sort+desc")
        expect(helper.call_number_query_list(document, order)).to include("range%5Blc_classification%5D%5Bend")
      end
    end

    context "no call number provided" do
      let(:document) { { "lc_call_number_display" => [""] } }

      it "does not genearte a query list" do
        expect(helper.call_number_query_list(document)).to be_nil
      end
    end
  end

  describe "#libraries_query_display(document)" do
    context "document found in 3 or more libraries" do
      let(:document) { { "library_facet" => ["Charles", "Ambler", "Japan"] } }

      it "Displays the first library and the text more locations" do
        expect(helper.libraries_query_display(document)).to include("More Locations")
      end
    end

    context "document found in 1 or 2 libraries" do
      let(:document) { { "library_facet" => ["Charles", "Ambler"] } }

      it "Displays the first and second libraries" do
        expect(helper.libraries_query_display(document)).to eq("<p class=\"mb-0 pb-0 text-truncate\">Charles<br />Ambler</p>")
      end
    end
  end

  describe "#format_classes_for_icons(document)" do
    context "Format type includes a space" do
      let(:document) { { "format" => ["Archival Material"] } }

      it "replaces whitespace with underscore and downcases the string" do
        expect(helper.format_classes_for_icons(document)).to eq("archival_material")
      end
    end

    context "Format type includes a slash" do
      let(:document) { { "format" => ["Journal/Periodical"] } }

      it "replaces slash with underscore and downcases the string" do
        expect(helper.format_classes_for_icons(document)).to eq("journal_periodical")
      end
    end
  end

  describe "#query_list_view_more_links" do
    let(:subject) { helper.query_list_view_more_links(params) }

    context "empty params supplied" do
      let(:params) { {} }

      it "should return a View More link to an empty search" do
        expect(subject).to match(/<a class="query-list-view-more.*" href="\/catalog">View More<\/a>/)
      end
    end

    context "with params supplied" do
      let(:params)  { { foo: "bar" } }

      it "should return View More link with params added as url query params" do
        expect(subject).to match(/<a class="query-list-view-more.*" href="\/catalog\?foo=bar">View More<\/a>/)
      end
    end

    context "with per_page param supplied" do
      let(:params)  { { foo: "bar", per_page: 3 } }

      it "should return View More link with params added execept :per_page as url query params" do
        expect(subject).to match(/<a class="query-list-view-more.*" href="\/catalog\?foo=bar">View More<\/a>/)
      end
    end
  end

  describe "#skip_links" do
    let(:subject) { helper.skip_links }

    before do
      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config) { config }
        allow(helper).to receive(:blacklight_configuration_context) { context }
      end
    end

    context "only 1 search field" do
      let(:config) { SearchController.blacklight_config }
      let(:context) { Blacklight::Configuration::Context.new(config) }
      let(:search_fields)  {  [["All Fields", "all_fields"]] }

      it "should link to the element with search_field id" do
        expect(subject).to have_link("Skip to search", href: "#search_field")
      end
    end

    context "multiple search fields" do
      let(:config) { CatalogController.blacklight_config }
      let(:context) { Blacklight::Configuration::Context.new(config) }
      let(:search_fields)  {  [["All Fields", "all_fields"], ["Title", "title"], ["Author/creator/contributor", "creator_t"]] }

      it "should link to the element with search_field_dropdown id" do
        expect(subject).to have_link("Skip to search", href: "#search_field_dropdown")
      end
    end
  end
end
