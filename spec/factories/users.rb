# frozen_string_literal: true

require Rails.root.join('spec', 'support', 'factory_bot_helpers')

FactoryBot.define do
  factory :user do
    email { "#{access_id}@psu.edu" }
    sequence(:access_id) { |n| FactoryBotHelpers.generate_access_id_from_name(name, n) }
    name { FFaker::Name.name }
    provider { 'MyString' }
    uid { 'MyString' }
  end
end
