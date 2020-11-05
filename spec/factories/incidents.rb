# frozen_string_literal: true

FactoryBot.define do
  factory :incident do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    category { Incident::ISSUE_TYPES.sample }
    subject { Faker::Coffee.blend_name }

    message { Faker::Lorem.paragraph }
  end

  trait :from_penn_state do
    transient do
      user { build(:user) }
    end

    name { user.name }
    email { user.email }
  end
end
