# frozen_string_literal: true

FactoryBot.define do
  factory :collection do
    association :depositor, :with_user, factory: :actor
    title { generate(:work_title) }
    description { Faker::Lorem.paragraph }
    visibility { Permissions::Visibility.default }

    # Postgres does this for us, but for testing, we can do it here to save having to call create/reload.
    uuid { SecureRandom.uuid }

    trait :with_creators do
      transient do
        creator_count { 1 }
      end

      after(:build, :stub) do |collection, evaluator|
        collection.creators = build_list(:authorship, evaluator.creator_count, :of_collection) do |creator, index|
          creator.resource = collection
          creator.position = index
        end
      end
    end

    trait :with_published_works do
      transient do
        published_work { create(:work, has_draft: false) }
      end

      works { [published_work] }
    end

    trait :with_complete_metadata do
      title { "Collection #{generate(:work_title)}" }
      subtitle { FactoryBotHelpers.work_title }
      keyword { Faker::Science.element }
      description { Faker::Lorem.paragraph }
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

    trait :with_a_doi do
      doi { FactoryBotHelpers.datacite_doi }
    end
  end
end
