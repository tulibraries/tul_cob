# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Bookmark All guest warning" do
  scenario "shows a warning after bookmarking all while logged out" do
    visit "/catalog?search_field=all_fields&q=japan"

    expect(page).to have_css("button.bookmark-all-btn")
    find("button.bookmark-all-btn").click

    expect(page).to have_text(I18n.t("blacklight.bookmarks.need_login"))
  end
end
