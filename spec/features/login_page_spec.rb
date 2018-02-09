# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Login Page" do

  xit "has a My Library Account link" do
    visit "/"
    expect(page).to have_link("My Library Account")
  end


  xit "does not have the typical login form" do
    visit "/users/sign_in"
    expect(page).not_to have_button("Log inh")
  end


  xit "has a link to shibboleth" do
    visit "/users/sign_in"
    expect(page).to have_link("Sign in with your AccessNet Username")
  end
end
