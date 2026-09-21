# frozen_string_literal: true

require "rails_helper"

RSpec.describe LibrarySearch::BookmarkAllComponent, type: :component do
  let(:documents) { [double(id: "A"), double(id: "B")] }
  let(:component) { described_class.new(documents:, document_type: "SolrDocument") }

  before do
    allow(component).to receive(:bookmarked_count).and_return(bookmarked_count)
  end

  context "when not all documents are bookmarked" do
    let(:bookmarked_count) { 1 }

    it "renders the Bookmark all form" do
      with_controller_class(CatalogController) do
        rendered = render_inline(component)

        expect(rendered.css("form.bookmark-all-form")).not_to be_empty
        expect(rendered.css("button.bookmark-all-btn.bookmarks-tools-btn").text).to include("Bookmark")
        expect(rendered.css("input[name='_method'][value='delete']")).to be_empty
        expect(rendered.css("input[name='bookmarks[][document_id]']").length).to eq(2)
      end
    end
  end

  context "when all documents are bookmarked" do
    let(:bookmarked_count) { 2 }

    it "renders the Unbookmark all form" do
      with_controller_class(CatalogController) do
        rendered = render_inline(component)

        expect(rendered.css("button.bookmark-all-btn.bookmarks-tools-btn").text).to include("Unbookmark")
        expect(rendered.css("input[name='_method'][value='delete']")).not_to be_empty
      end
    end
  end
end
