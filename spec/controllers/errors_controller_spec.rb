# frozen_string_literal: true

require "rails_helper"

RSpec.describe ErrorsController, type: :controller do
  render_views

  let (:sign_out_url) { Rails.configuration.devise[:sign_out_redirect_url] }

  it "ignores file extensions in url when a resource is not found" do
    get :not_found, params: { format: "txt" }
    expect(response).to have_http_status 404
    expect(response.body).to include "DOCTYPE html"
  end

  it "ignores file extensions in url when a server error arises" do
    get :internal_server_error, params: { format: "txt" }
    expect(response).to have_http_status 500
    expect(response.body).to include "DOCTYPE html"
  end
end
