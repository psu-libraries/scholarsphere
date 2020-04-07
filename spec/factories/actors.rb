# frozen_string_literal: true

require Rails.root.join('spec', 'support', 'factory_bot_helpers')

FactoryBot.define do
  factory :actor do
    given_name { Faker::Name.first_name }
    surname { Faker::Name.last_name }
    email { "#{psu_id}@psu.edu" }
    sequence(:psu_id) { |n| FactoryBotHelpers.generate_access_id_from_name(given_name, surname, n) }

    # The regex below takes an integer and formats it into 16 digits in groups
    # of 4, separated by '-'
    #   Example: 123 -> 0000-0000-0000-0123
    sequence(:orcid) { |n| format('%<n>016d', n: n).gsub(/(\d{4})(?!$)/, '\1-') }

    trait :with_user do
      user
    end
  end
end
