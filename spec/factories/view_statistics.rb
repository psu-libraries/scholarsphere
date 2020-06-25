# frozen_string_literal: true

FactoryBot.define do
  factory :view_statistic do
    count { Faker::Number.number(digits: 2) }
    with_work_version

    trait :with_work_version do
      association :resource, factory: :work_version
    end

    trait :with_collection do
      association :resource, factory: :collection
    end
  end
end
