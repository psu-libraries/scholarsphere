# frozen_string_literal: true

require Rails.root.join('spec', 'support', 'factory_bot_helpers')

FactoryBot.define do
  factory :actor do
    given_name { Faker::Name.first_name }
    surname { Faker::Name.last_name }
    email { "#{psu_id}@psu.edu" }
    sequence(:psu_id) { |n| FactoryBotHelpers.generate_access_id_from_name(given_name, surname, n) }

    orcid { FactoryBotHelpers.generate_orcid }

    trait :with_user do
      user
    end

    trait :without_an_orcid do
      orcid { nil }
    end

    trait :with_no_identifiers do
      orcid { nil }
      psu_id { nil }
    end
  end
end
