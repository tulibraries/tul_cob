# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Login Page" do

  it "has a My Library Account link" do
    visit "/"
    expect(page).to have_link("My Account")
  end


  it "does not have the typical login form" do
    visit "/users/sign_in"
    expect(page).not_to have_button("Log in")
  end


  it "has a link to shibboleth" do
    visit "/users/sign_in"
    expect(page).to have_link("Students, faculty, staff and registered alumni")
  end

  it "does not error out if we try to follow shibboleth path" do
    visit "/users/sign_in"
    click_link("Students, faculty, staff and registered alumni")
    expect(status_code).to be 200
  end
end
