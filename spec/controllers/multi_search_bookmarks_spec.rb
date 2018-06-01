# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookmarksController, type: :controller do
  it "sets a default bookmark_sources configuration" do
    bookmark_sources = controller.blacklight_config.bookmark_sources
    expected = [ :catalog, :primo_central ]
    expect(bookmark_sources).to eq(expected)
  end
end
