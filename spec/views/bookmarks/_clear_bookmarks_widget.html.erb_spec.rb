# frozen_string_literal: true

require "rails_helper"

RSpec.describe "bookmarks/_clear_bookmarks_widget.html.erb" do
  it "renders a turbo delete link to the clear bookmarks route" do
    render partial: "bookmarks/clear_bookmarks_widget"

    expect(rendered).to include("href=\"/bookmarks/clear\"")
    expect(rendered).to include("data-turbo-method=\"delete\"")
    expect(rendered).to include("data-turbo-confirm")
    expect(rendered).to include("clear-bookmarks")
  end
end
