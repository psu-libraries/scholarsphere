# frozen_string_literal: true

FactoryBot.define do
  factory :alias do
    creator
    display_name { Faker::Name.name }
  end
end
