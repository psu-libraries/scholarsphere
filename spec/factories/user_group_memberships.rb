# frozen_string_literal: true

FactoryBot.define do
  factory :user_group_membership do
    user
    group
  end
end
