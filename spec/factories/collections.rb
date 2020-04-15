# frozen_string_literal: true

FactoryBot.define do
  factory :collection do
    association :depositor, :with_user, factory: :actor

    # Postgres does this for us, but for testing, we can do it here to save having to call create/reload.
    uuid { SecureRandom.uuid }

    title { generate(:work_title) }

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
