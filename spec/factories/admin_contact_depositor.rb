# frozen_string_literal: true

FactoryBot.define do
  factory :admin_contact_depositor do
    send_to_name { Faker::Name.name }
    send_to_email { Faker::Internet.email }
    cc_email_to { [Faker::Internet.email, Faker::Internet.email] }
    subject { Faker::Coffee.blend_name }
    message { Faker::Lorem.paragraph }
  end
end
