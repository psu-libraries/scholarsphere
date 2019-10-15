# frozen_string_literal: true

FactoryBot.define do
  factory :work do
    association :depositor, factory: :user
    work_type { Work::Types.all.first }
  end
end
