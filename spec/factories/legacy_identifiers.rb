# frozen_string_literal: true

FactoryBot.define do
  factory :legacy_identifier do
    version { 1 }
    sequence(:old_id) { |n| format('old-id-%<n>06d', n: n) }
    with_work_version

    trait :with_work_version do
      resource factory: %i[work_version]
    end

    trait :with_work do
      resource factory: %i[work]
    end

    trait :with_collection do
      resource factory: %i[collection]
    end

    trait :with_file do
      resource factory: %i[file_resource]
    end
  end
end
