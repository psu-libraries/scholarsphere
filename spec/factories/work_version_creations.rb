# frozen_string_literal: true

FactoryBot.define do
  factory :work_version_creation do
    work_version
    actor
    add_attribute(:alias) { Faker::Name.name } # `alias` is a reserved keyword

    # @note we might want to do something fancy here in the future, to ensure
    # that the alias and the creator name are similiar/same.
  end
end
