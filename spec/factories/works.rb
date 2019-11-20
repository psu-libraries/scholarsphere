# frozen_string_literal: true

FactoryBot.define do
  factory :work do
    association :depositor, factory: :user
    work_type { Work::Types.all.first }

    transient do
      has_draft { true }
      versions_count { 1 }
    end

    # A work is not valid unless it has one or more versions. This block
    # automatically creates some versions—-if none already exist!--and allows
    # configuration for the number of versions to create, and whether one of
    # them should be a draft or not.
    after(:build) do |work, evaluator|
      next if work.versions.any? # Skip if there are already versions specified

      num_drafts_to_build = evaluator.has_draft ? 1 : 0
      num_published_to_build = evaluator.versions_count - num_drafts_to_build

      num_published_to_build.times do |n|
        work.versions << build(:work_version,
                               :published,
                               :with_complete_metadata,
                               work: work,
                               version_number: (n + 1))
      end

      if evaluator.has_draft
        work.versions << build(:work_version,
                               :draft,
                               :with_complete_metadata,
                               work: work,
                               version_number: (num_published_to_build + 1))
      end
    end
  end

  sequence(:work_title) do |n|
    FactoryBotHelpers.work_title(n)
  end
end
