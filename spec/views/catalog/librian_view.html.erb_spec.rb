# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/librarian_view.html.erb", type: :view do

  context "Empty mar_view " do
    it "displays the correct title name"  do
      assign(:marc_view, [])
      render
      expect(rendered).to match(/Staff View/)
    end
  end

  context "Non empty @marc_view" do
    it "displays the correct title name"  do
      assign(:marc_view, ["Hello World"])
      render
      expect(rendered).to match(/Staff View/)
      expect(rendered).to match(/Hello World/)
    end
  end

end
