# frozen_string_literal: true

require "rails_helper"

RSpec.describe QueryListHelper, type: :helper do
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
        expect(helper.query_list("foo", "tooltip", "q=bar")).to match(/<div.* data-controller="query-list".*data-query-list-url="\/query_list\?q=bar&per_page=5".*>/)
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
end
