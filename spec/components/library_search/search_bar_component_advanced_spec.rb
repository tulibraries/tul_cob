# frozen_string_literal: true

require "rails_helper"

RSpec.describe LibrarySearch::SearchBarComponent, type: :component do
  describe "#advanced_search_link_text" do
    {
      "/catalog/advanced" => "Advanced Search",
      "/journals/advanced" => "Advanced Journals Search",
      "/articles/advanced" => "Advanced Articles Search",
      "/databases/advanced" => "Advanced Databases Search"
    }.each do |advanced_search_url, label|
      it "uses the #{label} translation for #{advanced_search_url}" do
        component = described_class.new(url: "/catalog", params: {}, advanced_search_url: advanced_search_url)

        expect(component.advanced_search_link_text).to eq(label)
      end
    end

    it "uses the current search URL when the advanced search URL is generic" do
      component = described_class.new(
        url: "/databases",
        params: {},
        advanced_search_url: "/advanced"
      )

      expect(component.advanced_search_link_text).to eq("Advanced Databases Search")
      expect(component.advanced_search_url).to eq("/databases/advanced")
    end
  end

  let(:params) do
    ActionController::Parameters.new(
      q: "cat",
      search_field: "advanced",
      qt: "search",
      page: "2",
      utf8: "✓",
      q_1: "foo",
      q_2: "bar",
      q_3: "baz",
      f_1: "title",
      f_2: "author",
      f_3: "subject",
      operator: { q_1: "contains" },
      op_1: "AND",
      op_2: "OR",
      f: { format: ["Book"] },
      sort: "title_sort asc"
    )
  end

  it "excludes advanced search params from the basic search state" do
    component = described_class.new(url: "/catalog", params:)

    expect(component.instance_variable_get(:@params).to_unsafe_h).to eq(
      "f" => { "format" => ["Book"] },
      "sort" => "title_sort asc"
    )
  end
end
