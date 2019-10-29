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

      work.versions = (
        build_list(:work_version, num_published_to_build, :published, work: work) +
        build_list(:work_version, num_drafts_to_build, :draft, work: work)
      )
    end
  end

  sequence(:work_title) do |n|
    a = Faker::Lorem.words(rand(1..5)).join(' ').capitalize
    b = Faker::Lorem.words.join(', ')
    c = Faker::Lorem.words.join("'s ")
    id = n.ordinalize

    %(#{a}: "#{b}; #{id} #{c}")
  end
end
