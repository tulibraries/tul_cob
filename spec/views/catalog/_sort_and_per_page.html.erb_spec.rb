# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalog/_sort_and_per_page.html.erb" do
  let(:documents) { [double(id: "A"), double(id: "B")] }
  let(:response) { instance_double(Blacklight::Solr::Response, documents: documents) }
  let(:bookmarks_relation) { instance_double(ActiveRecord::Relation) }
  let(:user) { instance_double(User) }

  before do
    assign(:response, response)
    view.define_singleton_method(:show_pagination?) { false }
    view.define_singleton_method(:render_results_collection_tools) { |_options = {}| "" }
    view.define_singleton_method(:blacklight_config) { CatalogController.blacklight_config }
    view.define_singleton_method(:current_or_guest_user) { @spec_user }
    view.define_singleton_method(:current_user) { @spec_user }
    view.define_singleton_method(:controller_name) { "catalog" }
    view.define_singleton_method(:action_name) { "index" }
    view.instance_variable_set(:@spec_user, user)
    allow(user).to receive(:bookmarks).and_return(bookmarks_relation)
    allow(bookmarks_relation).to receive(:where)
      .with(document_id: %w[A B], document_type: "SolrDocument")
      .and_return(bookmarks_relation)
  end

  it "renders Bookmark All when not all documents are bookmarked" do
    allow(bookmarks_relation).to receive(:count).and_return(1)

    render partial: "catalog/sort_and_per_page"

    assert_select "form.bookmark-all-form" do
      assert_select "button", text: /Bookmark/
      assert_select "input[name='_method'][value='delete']", count: 0
      assert_select "input[name='bookmarks[][document_id]']", count: 2
      assert_select "input[name='bookmarks[][document_id]'][value='A']", count: 1
      assert_select "input[name='bookmarks[][document_id]'][value='B']", count: 1
    end
  end

  it "renders Unbookmark All when all documents are bookmarked" do
    allow(bookmarks_relation).to receive(:count).and_return(2)

    render partial: "catalog/sort_and_per_page"

    assert_select "form.bookmark-all-form" do
      assert_select "button", text: /Unbookmark/
      assert_select "input[name='_method'][value='delete']", count: 1
    end
  end
end
