# frozen_string_literal: true

FactoryBot.define do
  factory :access_control do
    access_level { 'MyString' }

    association(:agent, factory: :user)
    association(:resource, factory: :work)

    trait :with_user do
      association(:agent, factory: :user)
    end

    trait :with_group do
      association(:agent, factory: :group)
    end
  end
end
