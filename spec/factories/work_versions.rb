# frozen_string_literal: true

FactoryBot.define do
  factory :work_version do
    work
    aasm_state { WorkVersion::STATE_DRAFT }
    title { generate(:work_title) }

    trait :with_files do
      transient do
        file_count { 1 }
      end

      after(:build) do |work_version, evaluator|
        work_version.file_resources = build_list(:file_resource, evaluator.file_count)
      end
    end

    trait :draft do
      aasm_state { WorkVersion::STATE_DRAFT }
    end

    trait :published do
      with_files
      aasm_state { WorkVersion::STATE_PUBLISHED }
    end
  end
end
