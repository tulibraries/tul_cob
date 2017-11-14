# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/librarian_view.html.erb", type: :view do

  it "displays the correct title name"  do
    assign(:marc_view, [])
    render
    expect(rendered).to match(/Staff View/)
  end
end
