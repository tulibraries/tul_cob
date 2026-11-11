# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Active Storage routes", type: :request do
  let(:params) do
    { blob: { filename: "test.png", byte_size: 1024,
              checksum: "1B2M2Y8AsgTpgAmY7PhCfg==", content_type: "image/png" } }
  end

  it "does not mount any Active Storage routes" do
    paths = Rails.application.routes.routes.map { |route| route.path.spec.to_s }

    expect(paths.grep(%r{/rails/active_storage})).to be_empty
  end

  it "does not allow direct uploads" do
    expect {
      post "/rails/active_storage/direct_uploads", params:, as: :json
    }.not_to change(ActiveStorage::Blob, :count)

    expect(response).to have_http_status(:not_found)
  end

  it "does not expose the disk service upload endpoint" do
    put "/rails/active_storage/disk/some-token", params: "data"

    expect(response).to have_http_status(:not_found)
  end
end
