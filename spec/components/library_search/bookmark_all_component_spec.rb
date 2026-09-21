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

  context "when there are no documents" do
    let(:documents) { [] }
    let(:bookmarked_count) { 0 }

    it "does not render" do
      with_controller_class(CatalogController) do
        expect(render_inline(component).to_html).to be_blank
      end
    end
  end

  describe "#all_bookmarked?" do
    let(:bookmarked_count) { 0 }
    let(:bookmarks) { instance_double(ActiveRecord::Relation) }
    let(:user) { instance_double(User, bookmarks:) }
    let(:component_helpers) { instance_double("component helpers", current_or_guest_user: user) }

    before do
      allow(component).to receive(:bookmarked_count).and_call_original
      allow(component).to receive(:helpers).and_return(component_helpers)
      allow(bookmarks).to receive(:where)
        .with(document_id: %w[A B], document_type: "SolrDocument")
        .and_return(bookmarks)
    end

    it "uses the current user's bookmarks" do
      allow(bookmarks).to receive(:count).and_return(2)

      expect(component).to be_all_bookmarked
    end

    it "returns false when some documents are not bookmarked" do
      allow(bookmarks).to receive(:count).and_return(1)

      expect(component).not_to be_all_bookmarked
    end
  end
end
