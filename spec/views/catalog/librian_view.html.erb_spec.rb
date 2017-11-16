# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/librarian_view.html.erb", type: :view do
  it "displays the correct title name"  do
    render
    expect(rendered).to match(/Staff View<\/h3>/)
  end
end
