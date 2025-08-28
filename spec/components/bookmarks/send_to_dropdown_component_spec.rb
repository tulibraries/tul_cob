# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bookmarks::SendToDropdownComponent, type: :component do
  it "renders a single dropdown menu item for RIS that opens in a new tab" do
    component = described_class.new(documents: [], url_opts: { format: "ris", controller: "bookmarks", action: "index" })

    ris_action = Blacklight::Configuration::ToolConfig.new(name: :ris, key: :ris)
    allow(component).to receive(:actions).and_return([ris_action])

    allow_any_instance_of(ApplicationHelper).to receive(:ris_path).and_return("/bookmarks.ris")

    render_inline(component)

    expect(page).to have_css(".dropdown-menu .dropdown-item")
    expect(page).to have_css(".dropdown-menu a[target=\"_blank\"][rel=\"noopener\"]")
    expect(page).to have_css(".dropdown-menu a[href$=\".ris\"]")
  end
end
