# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/_sort_and_per_page.html.erb", type: :view do
  let(:documents) { [double(id: "A")] }
  let(:response) { instance_double(Blacklight::Solr::Response, documents:) }

  before do
    assign(:response, response)
    allow(view).to receive(:show_pagination?).and_return(false)
    allow(view).to receive(:controller_name).and_return("catalog")
    allow(view).to receive(:action_name).and_return("index")
    config = double(document_model: SolrDocument)
    view.define_singleton_method(:blacklight_config) { config }
    allow(view).to receive(:render_results_collection_tools)
      .with(wrapping_class: "search-widgets-inner")
      .and_return('<div class="search-widgets-inner"><button class="btn">Sort by relevance</button></div>'.html_safe)
    allow(view).to receive(:render).and_call_original
    allow(view).to receive(:render)
      .with(instance_of(LibrarySearch::BookmarkAllComponent))
      .and_return('<form class="bookmark-all-form"><button class="btn bookmarks-tools-btn bookmark-all-btn">Bookmark all</button></form>'.html_safe)
  end

  it "places Bookmark all alongside the collection tools" do
    render partial: "catalog/sort_and_per_page"

    expect(rendered).to have_css("#sortAndPerPage .search-widgets--catalog .search-widgets-inner")
    expect(rendered).to have_css("#sortAndPerPage .search-widgets--catalog > .bookmark-all-form")
    expect(rendered).to have_css("button.bookmarks-tools-btn.bookmark-all-btn")
  end

  it "does not render Bookmark all outside the catalog index" do
    allow(view).to receive(:action_name).and_return("show")
    expect(view).not_to receive(:render).with(instance_of(LibrarySearch::BookmarkAllComponent))

    render partial: "catalog/sort_and_per_page"
  end
end
