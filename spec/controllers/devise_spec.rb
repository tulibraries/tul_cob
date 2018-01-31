# frozen_string_literal: true

require "rails_helper"

RSpec.describe Devise::SessionController, type: :controller do

  describe "#after_sign_out_path_for" do
    it "should return the configured shib signout URL" do
      expect(controller.after_sign_out_path_for(:foo)).to eq(Rails.configuration.devise[:sign_out_redirect_url])
    end
  end
end
