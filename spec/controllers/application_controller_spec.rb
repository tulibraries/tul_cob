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
    context "anonymous user" do
      it "clears the caches" do
        delete(:clear_caches)
        expect(response.body).to match "Cache has been cleared"
      end
    end
  end
end
