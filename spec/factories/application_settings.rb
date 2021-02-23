# frozen_string_literal: true

FactoryBot.define do
  factory :application_setting do
    read_only_message { Faker::Company.bs }
    announcement { Faker::Lorem.paragraph }
  end
end
