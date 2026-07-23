# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Flipflop dashboard access", type: :request do
  include Devise::Test::IntegrationHelpers

  it "redirects an unauthenticated user to sign in" do
    get "/flipflop"

    expect(response).to redirect_to(new_user_session_path)
  end

  it "allows an authenticated user whose email is configured" do
    user = FactoryBot.create(
      :user,
      email: "authorized.user@example.edu"
    )

    allow(Rails.application).to receive(:config_for)
      .with(:flipflop)
      .and_return(
        allowed_emails: ["authorized.user@example.edu"]
      )

    sign_in user

    get "/flipflop"

    expect(response).to have_http_status(:ok)
  end

  it "allows an authenticated user whose configured email differs only by case" do
    user = FactoryBot.create(
      :user,
      email: "Authorized.User@Example.edu"
    )

    allow(Rails.application).to receive(:config_for)
      .with(:flipflop)
      .and_return(
        allowed_emails: [
          "authorized.user@example.EDU"
        ]
      )

    sign_in user

    get "/flipflop"

    expect(response).to have_http_status(:ok)
  end

  it "forbids an authenticated user whose email is not configured" do
    user = FactoryBot.create(
      :user,
      email: "unauthorized.user@example.edu"
    )

    allow(Rails.application).to receive(:config_for)
      .with(:flipflop)
      .and_return(
        allowed_emails: ["authorized.user@example.edu"]
      )

    sign_in user

    get "/flipflop"

    expect(response).to have_http_status(:forbidden)
  end
end
