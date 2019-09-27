# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_bot
FactoryBot.define do
  factory :user do
    encrypted_password { "asdfjkl;" }
    uid { "patron12345" }
    provider { "libprovidr" }
    guest { false }
  end

  factory :user_admin, class: User do
    password { "secret" }
    password_confirmation { "secret" }
    uid { "staff12345" }
    email { "admin@example.edu" }
    guest { false }
    admin { true }
    name { "Slarty Bartfast" }
    last_name { "Bartfast" }
    first_name { "Slarty" }
  end
end
