# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, type: :controller do

  let (:sign_out_url) { Rails.configuration.devise[:sign_out_redirect_url] }

  it "should return the configured shib signout URL" do
    request.params[:type] = "sso"
    sign_out_url = controller.after_sign_out_path_for(:foo)
    expect(sign_out_url).to_not be_nil
    expect(controller.after_sign_out_path_for(:foo)).to eq(sign_out_url)
  end

  describe "DELETE #clear_caches action" do
    # We disable forgery protection by default in  our test environment.
    # We need to enable it to properly test this endpoint.
    around do |example|
      original_setting = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
      example.run
    ensure
      ActionController::Base.allow_forgery_protection = original_setting
    end

    context "anonymous user" do
      it "clears the caches" do
        request.headers["Authorization"] = "Bearer token"
        delete(:clear_caches)
        expect(response.body).to match "Cache has been cleared"
      end
    end
  end
end
