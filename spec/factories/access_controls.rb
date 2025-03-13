# frozen_string_literal: true

FactoryBot.define do
  factory :access_control do
    access_level { AccessControl::Level.default }

    agent factory: %i[user]
    resource factory: %i[work]

    trait :with_user do
      agent factory: %i[user]
    end

    trait :with_group do
      agent factory: %i[group]
    end
  end
end
