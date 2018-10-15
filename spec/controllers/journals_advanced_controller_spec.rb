# frozen_string_literal: true

require "rails_helper"

RSpec.describe JournalsAdvancedController, type: :controller do

  it "overrides the catalog Search Builder" do
    expect(controller.blacklight_config.search_builder_class).to eq(JournalsSearchBuilder)
  end

  it "overrides the document model" do
    expect(controller.blacklight_config.document_model).to eq(SolrJournalDocument)
  end

  it "overrides the search_action_url" do
    expect(controller.send(:search_action_url)).to eq("/journals/advanced")
  end
end
