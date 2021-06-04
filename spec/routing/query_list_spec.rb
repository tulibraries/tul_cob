# frozen_string_literal: true

require "rails_helper"

RSpec.describe "query_list routing", type: :request do

  it "should be defined" do
    get "/query_list?q=foo"
    expect(response).to have_http_status 200
  end
end
