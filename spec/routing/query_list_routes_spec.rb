# frozen_string_literal: true

require "rails_helper"

RSpec.describe "query_list routes", type: :routing do
  it "routes GET requests to the show action" do
    expect(get: "/query_list").to route_to(controller: "query_list", action: "show")
  end

  it "does not expose non-show actions" do
    expect(post: "/query_list").not_to be_routable
  end
end
