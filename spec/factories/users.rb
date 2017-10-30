# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot
FactoryBot.define do
  factory :user do
    encrypted_password "asdfjkl;"
    uid "patron12345"
    provider "libprovidr"
    guest false
  end
end
