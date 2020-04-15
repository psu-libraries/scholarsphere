# frozen_string_literal: true

FactoryBot.define do
  factory :collection_work_membership do
    collection
    work
    position { nil }
  end
end
