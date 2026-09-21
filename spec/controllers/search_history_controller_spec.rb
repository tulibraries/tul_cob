# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchHistoryController, type: :controller do
  it "includes Blacklight search history behavior" do
    expect(described_class.ancestors).to include(Blacklight::SearchHistory)
  end
end
