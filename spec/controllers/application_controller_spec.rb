# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller do
    def invalid_authenticity_token
      raise ActionController::InvalidAuthenticityToken
    end
  end

  let (:sign_out_url) { Rails.configuration.devise["sign_out_redirect_url"] }

  before do
    routes.draw do
      get "invalid_authenticity_token" => "anonymous#invalid_authenticity_token"
    end
  end

  it "should return the configured shib signout URL" do
    request.params[:type] = "sso"
    sign_out_url = controller.after_sign_out_path_for(:foo)
    expect(sign_out_url).to_not be_nil
    expect(controller.after_sign_out_path_for(:foo)).to eq(sign_out_url)
  end

  it "redirects to root when referer is missing", with_rescue: true do
    get :invalid_authenticity_token

    expect(response).to redirect_to("/")
    expect(flash[:notice]).to eq("Your search results page had to be reloaded. Please try again.")
  end

end
