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
end
