# frozen_string_literal: true

require "rails_helper"

RSpec.describe QueryListComponent, type: :component do

  let(:params) { ActionController::Parameters.new query_list: "true" }
  let(:tooltip) { nil }
  let(:document) { nil }
  let(:query) { "" }
  let(:footer_field) { nil }
  let(:title) { nil }
  let(:component) { QueryListComponent.new(title:,
                                           tooltip:,
                                           query:,
                                           footer_field:,
                                           document:) }
  let(:subject) { render_inline(component).to_html  }

  context "title and query provided" do
    let(:title) { "foo" }
    let(:query)  { "q=bar" }

    it "sets data-controller=\"query-list\" div" do
      expect(subject).to match(/<div.* data-controller="query-list".*>/)
    end

    it "sets data-query-list-url" do
      expect(subject).to match(/<div.* data-controller="query-list".*data-query-list-url="\/query_list\?q=bar&amp;per_page=5".*>/)
    end

    it "sets tile to link 'foo' that links back to the query" do
      expect(subject).to match(/<h.*><a href="\/catalog\?q=bar">foo<\/a><\/h.*>/)
    end

    it "sets a target div called data-target=\"query-list.results\"" do
      expect(subject).to match(/<div.*data-query-list-target="results".*>/)
    end
  end

  context "@document.id is available" do
    let(:document) { SolrDocument.new(id: "fizz") }

    it "adds the filer_id query param" do
      expect(subject).to match(/filter_id=fizz/)
    end
  end

  context "@document.id is NOT available" do
    it "does NOT add the filer_id query param" do
      expect(subject).not_to match(/filter_id=fizz/)
    end
  end

  context "footer_field is passed" do
    let(:footer_field) { "buzz" }
    it "adds a footer_field query param" do
      expect(subject).to match(/footer_field=buzz/)
    end
  end
end
