# frozen_string_literal: true

require "rails_helper"

RSpec.describe ErrorsController, type: :controller do
  render_views

  let (:sign_out_url) { Rails.configuration.devise[:sign_out_redirect_url] }

  it "ignores file extensions in url when a resource is not found" do
    get :not_found, params: { format: "txt" }
    expect(response.status).to eq(404)
    expect(response.body).to include "DOCTYPE html"
  end

  it "returns plain text for RIS not found requests" do
    get :not_found, params: { format: "ris" }
    expect(response.status).to eq(400)
    expect(response.media_type).to eq("text/plain")
  end

  it "ignores file extensions in url when a server error arises" do
    get :internal_server_error, params: { format: "txt" }
    expect(response.status).to eq(500)
    expect(response.body).to include "DOCTYPE html"
  end

  describe "before_action get_manifold_alerts" do
    context ":internal_server_error" do
      it "sets @manifold_alerts_thread" do
        get :internal_server_error
        expect(controller.instance_variable_get("@manifold_alerts_thread")).to be_kind_of(Thread)
      end
    end

    context ":not_found" do
      it "sets @manifold_alerts_thread" do
        get :not_found
        expect(controller.instance_variable_get("@manifold_alerts_thread")).to be_kind_of(Thread)
      end
    end
  end
end
