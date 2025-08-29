# frozen_string_literal: true

require "rails_helper"

RSpec.describe TulThumbnailComponent, type: :component do
  context "component without gb_preview" do
    subject(:component_1) { described_class.new(presenter:) }

    let(:document) { { isbn_display: ["123456789"] } }
    let(:presenter) { OpenStruct.new(heading: "Book 1", document:) }

    it "renders the component without google books preview" do
      render_inline(component_1)
      expect(page).to have_css("img", class: "book_cover")
      expect(page).to_not have_css("a", class: "preview")
    end
  end

  context "component with gb_preview" do
    subject(:component_2) { described_class.new(presenter:, gb_preview: true) }

    let(:document) { { isbn_display: ["987654321"] } }
    let(:presenter) { OpenStruct.new(heading: "Book 2", document:) }

    it "renders the component with google books preview" do
      render_inline(component_2)
      expect(page).to have_css("a", class: "preview")
    end
  end
end
