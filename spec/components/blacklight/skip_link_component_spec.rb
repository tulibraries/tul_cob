# frozen_string_literal: true

require "rails_helper"

RSpec.describe TulSkipLinkComponent, type: :component do
  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.search_fields = { "all_fields" => "", "title" => "" }
    end
  end

  before do
    allow(vc_test_controller).to receive(:blacklight_config).and_return(blacklight_config)
    allow(vc_test_controller).to receive(:controller_name).and_return(controller_name)
    allow(vc_test_controller).to receive(:action_name).and_return(action_name)
    render_inline(described_class.new)
  end

  context "on a standard page" do
    let(:controller_name) { "catalog" }
    let(:action_name) { "show" }

    it "renders links to the main content, search, and filters" do
      expect(page).to have_link("Skip to main content", href: "#main-container")
      expect(page).to have_link("Skip to search", href: "#q")
      expect(page).to have_link("Skip to search filters", href: "#search_field")
    end
  end

  context "on the search index" do
    let(:controller_name) { "search" }
    let(:action_name) { "index" }

    it "does not render a link to the filters" do
      expect(page).to have_link("Skip to search", href: "#q")
      expect(page).not_to have_link("Skip to search filters", href: "#search_field")
    end
  end

  context "on an advanced search page" do
    let(:controller_name) { "catalog" }
    let(:action_name) { "advanced_search" }

    it "does not render links to the standard search or filters" do
      expect(page).to have_link("Skip to main content", href: "#main-container")
      expect(page).not_to have_link("Skip to search")
      expect(page).not_to have_link("Skip to search filters")
    end
  end
end
