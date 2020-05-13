# frozen_string_literal: true

FactoryBot.define do
  factory :legacy_identifier do
    version { 1 }
    sequence(:old_id) { |n| format('old-id-%<n>06d', n: n) }
    with_work_version

    trait :with_work_version do
      association :resource, factory: :work_version
    end

    trait :with_work do
      association :resource, factory: :work
    end

    trait :with_collection do
      association :resource, factory: :collection
    end
  end
end
