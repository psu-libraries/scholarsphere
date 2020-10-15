# frozen_string_literal: true

FactoryBot.define do
  factory :external_app, aliases: [:application] do
    name { Faker::App.name }
    contact_email { Faker::Internet.email }
  end
end
