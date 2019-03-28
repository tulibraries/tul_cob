# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebContentController, type: :controller do
  it "overrides the document model" do
    expect(controller.blacklight_config.document_model).to eq(SolrWebContentDocument)
  end

  it "overrides the config connection url" do
    url = controller.blacklight_config.connection_config[:url]
    web_content_url = controller.blacklight_config.connection_config[:web_content_url]
    expect(url).to eq(web_content_url)
  end
end
