# frozen_string_literal: true

FactoryBot.define do
  factory :work_creation do
    association(:alias) # `alias` is a reserved word in Ruby
    work
  end
end
