# frozen_string_literal: true

FactoryBot.define do
  factory :authorship do
    given_name { Faker::Name.first_name }
    surname { Faker::Name.last_name }
    display_name { "#{Faker::Name.prefix} #{given_name} #{surname}" }
    email { Faker::Internet.email(name: given_name) }
    sequence(:position)
    of_work

    trait :of_work do
      resource factory: %i[work_version]
    end

    trait :of_collection do
      resource factory: %i[collection]
    end

    trait :with_orcid do
      actor
    end

    trait :with_actor do
      actor
    end
  end
end
