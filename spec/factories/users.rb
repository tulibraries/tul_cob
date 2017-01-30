# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    email "patron@example.edu"
    encrypted_password "asdfjkl;"
    uid "123456"
    guest false
  end
end

