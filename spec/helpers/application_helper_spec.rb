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
end
