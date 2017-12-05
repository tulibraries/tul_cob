# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/librarian_view.html.erb", type: :view do
  before(:each) do
    @document = SolrDocument.new(id: 1)
  end

  it "renders as expected"  do
    render
    expect(rendered).to match(/Staff View<\/h3>/)
    expect(rendered).to match(/Back to Main View/)
    expect(rendered).to_not match(/×<\/button>/)
  end
end
