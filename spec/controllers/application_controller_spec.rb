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

  describe "#campus_closed?" do
    it "returns false with an empty params object method" do
      expect(controller.campus_closed?).to be(false)
    end
    it "returns true when campus_closed param is not 'false'" do
      controller.params["campus_closed"] = "true"
      expect(controller.campus_closed?).to be(true)
    end
  end
end
