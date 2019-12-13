# frozen_string_literal: true

require Rails.root.join('spec', 'support', 'factory_bot_helpers')

FactoryBot.define do
  factory :user do
    trait :admin do
      groups { [Group.new(name: Rails.application.config.admin_group)] }
    end
    email { "#{access_id}@psu.edu" }
    sequence(:access_id) { |n| FactoryBotHelpers.generate_access_id_from_name(given_name, surname, n) }
    given_name { Faker::Name.first_name }
    surname { Faker::Name.last_name }
    provider { 'psu' }
    uid { access_id }
  end
end
