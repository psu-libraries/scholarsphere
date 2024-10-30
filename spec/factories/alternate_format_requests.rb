# frozen_string_literal: true

require Rails.root.join('spec', 'support', 'factory_bot_helpers')

FactoryBot.define do
  factory :alternate_format_request do
    email { Faker::Internet.email }
    url { Faker::Internet.url }
    message { Faker::Lorem.sentence }
    name { Faker::Name.name }
    title { Faker::Lorem.sentence }
  end
end
