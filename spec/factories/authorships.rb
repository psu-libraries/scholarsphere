# frozen_string_literal: true

FactoryBot.define do
  factory :authorship do
    given_name { Faker::Name.first_name }
    surname { Faker::Name.last_name }
    display_name { "#{Faker::Name.prefix} #{given_name} #{surname}" }
    email { Faker::Internet.email(name: given_name) }
    of_work

    trait :of_work do
      association(:resource, factory: :work_version)
    end

    trait :of_collection do
      association(:resource, factory: :collection)
    end

    trait :with_orcid do
      association(:actor)
    end

    trait :with_actor do
      association(:actor)
    end
  end
end
