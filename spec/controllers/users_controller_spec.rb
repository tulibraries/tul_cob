require 'rails_helper'

RSpec.describe UsersController, type: :controller do

  describe "GET #loans" do
    it "returns http success" do
      get :loans
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #holds" do
    it "returns http success" do
      get :holds
      expect(response).to have_http_status(:success)
    end
  end

end
