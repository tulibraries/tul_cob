# frozen_string_literal: true

require "rails_helper"

RSpec.describe QueryListController, type: :controller do

  describe "show action" do
    it "sets the @docs params" do
      get :show, params: { q: "test" }
      expect(controller.instance_variable_get("@docs")).to be_a_kind_of(Array)
    end
  end
end
