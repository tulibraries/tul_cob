# frozen_string_literal: true

require "rails_helper"

RSpec.describe "upgrade-sensitive routes", type: :routing do
  it "keeps the root route pointed at the search controller" do
    expect(get: "/").to route_to(controller: "search", action: "index")
  end

  it "routes article records to Primo Central" do
    expect(get: "/articles/123").to route_to(
      controller: "primo_central",
      action: "show",
      id: "123"
    )
  end

  it "provides the Primo Central document helper" do
    expect(Rails.application.routes.url_helpers.primo_central_document_path("123"))
      .to eq("/articles/123")
  end

  it "routes Primo Central tracking requests" do
    expect(post: "/articles/123/track").to route_to(
      controller: "primo_central",
      action: "track",
      id: "123"
    )
  end
end
