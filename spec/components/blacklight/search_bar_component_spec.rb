# frozen_string_literal: true

require "rails_helper"

RSpec.describe Blacklight::SearchBarComponent, type: :component do
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
