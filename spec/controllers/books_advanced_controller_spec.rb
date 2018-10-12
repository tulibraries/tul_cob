# frozen_string_literal: true

require "rails_helper"

RSpec.describe BooksAdvancedController, type: :controller do

  it "overrides the catalog Search Builder" do
    expect(controller.blacklight_config.search_builder_class).to eq(BooksSearchBuilder)
  end

  it "overrides the document model" do
    expect(controller.blacklight_config.document_model).to eq(SolrBookDocument)
  end

  it "overrides the search_action_url" do
    expect(controller.send(:search_action_url)).to eq("/books/advanced")
  end
end
