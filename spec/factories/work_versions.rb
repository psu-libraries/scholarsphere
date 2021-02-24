# frozen_string_literal: true

FactoryBot.define do
  factory :work_version do
    work
    aasm_state { WorkVersion::STATE_DRAFT }
    title { generate(:work_title) }
    sequence(:version_number) { |n| work.present? ? work.versions.length + 1 : n }
    rights { WorkVersion::Licenses.active.sample[:id] }

    # Postgres does this for us, but for testing, we can do it here to save having to call create/reload.
    uuid { SecureRandom.uuid }

    trait :with_creators do
      transient do
        creator_count { 1 }
      end

      after(:build, :stub) do |work_version, evaluator|
        work_version.creators = build_list(:authorship, evaluator.creator_count) do |creator, index|
          creator.resource = work_version
          creator.position = index
        end
      end
    end

    trait :with_files do
      transient do
        file_count { 1 }
      end

      after(:build, :stub) do |work_version, evaluator|
        work_version.file_resources = build_list(:file_resource, evaluator.file_count)
      end
    end

    # Bare minimum for a valid draft
    trait :draft do
      aasm_state { WorkVersion::STATE_DRAFT }
    end

    # A draft that has everything needed to pass validations and be published
    trait :able_to_be_published do
      draft
      with_files
      with_creators
      description { Faker::Lorem.paragraph }
      published_date { Faker::Date.between(from: 2.years.ago, to: Date.today).iso8601 }
    end

    # A valid published work-version
    trait :published do
      able_to_be_published
      aasm_state { WorkVersion::STATE_PUBLISHED }
    end

    # A valid withdrawn work version
    # Note: this does not represent a version that was published and then withdrawn.
    trait :withdrawn do
      able_to_be_published
      aasm_state { WorkVersion::STATE_WITHDRAWN }
    end

    trait :with_complete_metadata do
      title { generate(:work_title) }
      subtitle { FactoryBotHelpers.work_title }
      keyword { Faker::Science.element }
      description { Faker::Lorem.paragraph }
      resource_type { Faker::House.furniture }
      contributor { Faker::Artist.name }
      publisher { Faker::Book.publisher }
      published_date { Faker::Date.between(from: 2.years.ago, to: Date.today).iso8601 }
      subject { Faker::Book.genre }
      language { Faker::Nation.language }
      identifier { Faker::Number.leading_zero_number(digits: 10) }
      based_near { FactoryBotHelpers.fancy_geo_location }
      related_url { Faker::Internet.url }
      source { Faker::SlackEmoji.emoji }
    end
  end
end
