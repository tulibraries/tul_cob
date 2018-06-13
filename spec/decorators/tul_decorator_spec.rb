# frozen_string_literal: true

require "rails_helper"

RSpec.describe TulDecorator, type: :view do
  include BentoSearch

  def decorator(hash = {}, view)
    TulDecorator.new(
      BentoSearch::ResultItem.new(hash), view
    )
  end
end
