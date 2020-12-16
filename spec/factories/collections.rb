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
        actors = build_list(:actor, evaluator.creator_count)

        actors.each do |actor|
          # Alias "Pat Doe" to "Dr. Pat Doe"
          creator_alias = "#{Faker::Name.prefix} #{actor.given_name} #{actor.surname}"
          collection.creator_aliases.build(
            actor: actor,
            alias: creator_alias
          )
        end
      end
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
      doi { FactoryBotHelpers.valid_doi }
    end
  end
end
