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
    expect(find_link(class: 'temple-user-link')).to be
  end

  it "does not error out if we try to follow shibboleth path" do
    visit "/users/sign_in"

    # TODO: Figure out what is leaving behind a signed in user
    # and remove this otherwise unnecessary stub.
    stub_request(:get, /.*almaws\/v1\/users\/.*/).
      to_return(status: 200,
                headers: { "Content-Type" => "application/json" },
                body: JSON.dump({
                  fees: { value: 0.0 },
                  user_group: { value: "2" }
                }))

    click_on(class: 'temple-user-link')
    expect(status_code).to be 200
  end
end
