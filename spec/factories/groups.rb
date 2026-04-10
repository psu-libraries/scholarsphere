# frozen_string_literal: true

FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "#{Faker::Currency.code.downcase}_#{n}" }
  end
end
