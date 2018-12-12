# frozen_string_literal: true

require "rails_helper"

RSpec.describe DatabasesController, type: :controller do
  it "overrides the document model" do
    expect(controller.blacklight_config.document_model).to eq(SolrDatabaseDocument)
  end

  it "overrides the config connection url" do
    url = controller.blacklight_config.connection_config[:url]
    az_url = controller.blacklight_config.connection_config[:az_url]
    expect(url).to eq(az_url)
  end
end
