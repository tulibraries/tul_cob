# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, type: :controller do

  # Overrides Devise::Controllers::Helpers#after_sign_out_path_for
  describe "#after_sign_out_path_for" do
    let (:sign_out_url) { Rails.configuration.devise[:sign_out_redirect_url] }

    it "should return the configured shib signout URL" do
      sign_out_url = controller.after_sign_out_path_for(:foo)
      expect(sign_out_url).to_not be_nil
      expect(controller.after_sign_out_path_for(:foo)).to eq(sign_out_url)
    end
  end
end
