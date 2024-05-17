# frozen_string_literal: true

require "rails_helper"

RSpec.describe "random 404", type: :request do

  it "should redirect /errors/:not_found" do
    get "/foobar"
    expect(response).to have_http_status 404
  end
end
