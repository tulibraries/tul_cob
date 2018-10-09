# frozen_string_literal: true

require "rails_helper"

RSpec.describe JournalsController, type: :controller do

  it "overrides the catalog Search Builder" do
    expect(controller.blacklight_config.search_builder_class).to eq(JournalsSearchBuilder)
  end

  it "overrides the document model" do
    expect(controller.blacklight_config.document_model).to eq(SolrJournalDocument)
  end
end
