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

    context "citeproc citations enabled" do
      before do
        allow(Flipflop).to receive(:citeproc_citations?).and_return(true)
      end

      it "displays APA without edition" do
        expect(citation_labels("APA")).to eq("APA")
      end

      it "displays MLA without edition" do
        expect(citation_labels("MLA")).to eq("MLA")
      end

      it "displays Chicago Author-Date without edition" do
        expect(citation_labels("CHICAGO-AUTHOR-DATE")).to eq("Chicago Author-Date")
      end

      it "displays Chicago Notes & Bibliography without edition" do
        expect(citation_labels("CHICAGO-NOTES-BIBLIOGRAPHY")).to eq("Chicago Notes & Bibliography")
      end
    end
  end

  describe "#emergency_alert_messages" do
    context "for_header is false" do
      it "does return the scroll_text" do
        helper.instance_variable_set("@manifold_alerts_thread", get_manifold_alerts)
        expect(helper.emergency_alert_messages).to have_text("Test banner message")
      end
    end

    context "@manifold_alerts_thread is nil" do
      it "does return the scroll_text" do
        helper.instance_variable_set("@manifold_alerts_thread", nil)
        expect(helper.emergency_alert_messages).to eq(nil)
      end
    end
  end

  describe "#emergency_alert_link" do
    context "link field is present" do
      it "does return the link" do
        helper.instance_variable_set("@manifold_alerts_thread", get_manifold_alerts)
        expect(helper.emergency_alert_messages).to have_text(/Click here to see full details./)
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

    context "nil value" do
      it "returns empty array []" do
        helper.instance_variable_set("@manifold_alerts_thread", Thread.new { nil })
        expect(helper.manifold_alerts).to eq(nil)
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

  describe "#creator_links(args)" do
    let(:search_article_search_path) { "article" }
    let(:search_catalog_path) { "catalog" }

    before do
      allow(helper).to receive(:search_article_search_path) { search_article_search_path }
      allow(helper).to receive(:search_catalog_path) { search_catalog_path }
    end

    context "no article creator" do
      let(:controller_name) { "primo_central" }
      let(:args) { { document: { creator: [""] }, field: :creator } }

      it "returns an empty list if no creators are available" do
        expect(creator_links(args)).to eq([""])
      end
    end

    context "an article creator" do
      let(:controller_name) { "primo_central" }
      let(:args) { { document: { creator: ["Louisa May Alcott"] }, field: :creator } }

      it "returns a list of links to creator search for each creator" do
        expect(creator_links(args)).to eq([
          "<a href=\"http://test.host/articles?search_field=creator&amp;q=Louisa May Alcott\">Louisa May Alcott</a>"
      ])
      end
    end

    context "an article creator with an integer value" do
      let(:controller_name) { "primo_central" }
      let(:args) { { document: { creator: ["372"] }, field: :creator } }

      it "returns a list of links to creator search for each creator without erroring" do
        expect(creator_links(args)).to eq([
          "<a href=\"http://test.host/articles?search_field=creator&amp;q=372\">372</a>"
      ])
      end
    end

    context "an article creator with comma separator" do
      let(:controller_name) { "primo_central" }
      let(:args) { { document: { creator: ["Louisa May Alcott", "Emily Dickinson"] }, field: :creator, config: { separator: ", " } } }

      it "returns a list of links to creator search for each creator, with comma seaprator" do
        expect(creator_links(args)).to eq(
          "<a href=\"http://test.host/articles?search_field=creator&amp;q=Louisa May Alcott\">Louisa May Alcott</a>, <a href=\"http://test.host/articles?search_field=creator&amp;q=Emily Dickinson\">Emily Dickinson</a>"
      )
      end
    end

    context "an article creator with a null value" do
      let(:controller_name) { "primo_central" }
      let(:args) { { document: { creator: ["null", "Emily Dickinson"] }, field: :creator } }

      it "returns a list of links without null values" do
        expect(creator_links(args)).to_not include([
          "<a href=\"http://test.host/articles?search_field=creator&amp;q=null\">null</a>"
        ])
        expect(creator_links(args)).to eq([
          "<a href=\"http://test.host/articles?search_field=creator&amp;q=Emily Dickinson\">Emily Dickinson</a>"
        ])
      end
    end

    context "no catalog creator" do
      let(:controller_name) { "primo_central" }
      let(:args) { { document: { creator_facet: [""] }, field: :creator_facet } }

      it "returns an empty list if no creators are available" do
        expect(creator_links(args)).to eq([""])
      end
    end

    context "a catalog creator" do
      let(:controller_name) { "primo_central" }
      let(:args) { { document: { creator_facet: ["Louise Penny"] }, field: :creator_facet } }

      it "returns a list of links to creator search for each creator" do
        expect(creator_links(args)).to eq([
          "<a href=\"http://test.host/articles?search_field=creator&amp;q=Louise Penny\">Louise Penny</a>"
      ])
      end
    end

    context "catalog creator is empty json" do
      let(:controller_name) { "catalog" }
      let(:args) { { document: { creator_display: ["{\"relation\":\"\",\"name\":\"\",\"role\":\"\"}"] },
      field: :creator_display } }

      it "returns an empty string list" do
        expect(creator_links(args)).to eq([""])
      end
    end

    context "catalog creator is json with role only " do
      let(:controller_name) { "catalog" }
      let(:args) { { document: { creator_display: ["{\"relation\":\"\",\"name\":\"\",\"role\":\"MyRole\"}"] },
      field: :creator_display } }

      it "returns role in a list" do
        expect(creator_links(args)).to eq(["MyRole"])
      end
    end

    context "catalog creator is json with relation only " do
      let(:controller_name) { "catalog" }
      let(:args) { { document: { creator_display: ["{\"relation\":\"MyRelation\",\"name\":\"\",\"role\":\"\"}"] },
      field: :creator_display } }

      it "returns role in a list" do
        expect(creator_links(args)).to eq(["MyRelation"])
      end
    end

    context "catalog creator is json with name only" do
      let(:controller_name) { "catalog" }
      let(:args) { { document: { creator_display: ["{\"relation\":\"\",\"name\":\"MyName\",\"role\":\"\"}"] },
      field: :creator_display } }

      it "returns name as a link to query" do
        expect(creator_links(args)).to eq([
          "<a href=\"catalog?f[creator_facet][]=MyName\">MyName</a>"
      ])
      end
    end

    context "catalog creator is json with name and role" do
      let(:controller_name) { "catalog" }
      let(:args) { { document: { creator_display: ["{\"relation\":\"\",\"name\":\"MyName\",\"role\":\"MyRole\"}"] },
      field: :creator_display } }

      it "returns name as a link to query + plus role appended" do
        expect(creator_links(args)).to eq([
          "<a href=\"catalog?f[creator_facet][]=MyName\">MyName</a> MyRole"
       ])
      end
    end

    context "catalog creator is json with name and role and relation" do
      let(:controller_name) { "catalog" }
      let(:args) { { document: { creator_display: ["{\"relation\":\"MyRelation\",\"name\":\"MyName\",\"role\":\"MyRole\"}"] },
      field: :creator_display } }

      it "returns name as a link to query + plus role appended + relation prepended" do
        expect(creator_links(args)).to eq([
          "MyRelation <a href=\"catalog?f[creator_facet][]=MyName\">MyName</a> MyRole"
      ])
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

  describe "#with_libguides?" do
    before do
      allow(helper).to receive(:params) { params }
    end

    context "params with_libguides is not set" do
      let(:params) { {} }

      it "returns false with an empty params object method" do
        expect(with_libguides?).to be(false)
      end
    end

    context "params with_libguides is true" do
      let(:params) { { "with_libguides" => "true" } }

      it "returns true when with_libguides param is not 'false'" do
        expect(with_libguides?).to be(true)
      end
    end

    context "params with_libguides is false" do
      let(:params) { { "with_libguides" => "false" } }

      it "returns false with an empty params object method" do
        expect(with_libguides?).to be(false)
      end
    end
  end
end
