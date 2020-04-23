# frozen_string_literal: true

FactoryBot.define do
  factory :collection_creation do
    collection
    actor
    add_attribute(:alias) { Faker::Name.name } # `alias` is a reserved keyword
  end
end
