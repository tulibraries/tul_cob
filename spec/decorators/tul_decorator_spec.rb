# frozen_string_literal: true

require "rails_helper"

RSpec.describe TulDecorator, type: :view do
  include BentoSearch

  def decorator(hash = {}, view)
    TulDecorator.new(
      BentoSearch::ResultItem.new(hash), view
    )
  end

  it "Adds 'Publisher' label to publisher info: " do
    item = decorator({ publisher: "foo" }, view)
    expected = "<span class=\"source_label\">Published: </span><span class=\"publisher\">foo</span>. "
    expect(item.render_source_info).to eq(expected)
  end

end
