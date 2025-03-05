# frozen_string_literal: true

require Rails.root.join('spec', 'support', 'factory_bot_helpers')

FactoryBot.define do
  factory :user do
    trait :admin do
      groups { User.default_groups + [Group.new(name: Rails.application.config.admin_group)] }
      admin_enabled { true }
    end
    groups { User.default_groups }
    email { "#{access_id}@psu.edu" }
    sequence(:access_id) { |n| FactoryBotHelpers.generate_access_id_from_name(Faker::Name.first_name, Faker::Name.last_name, n) }
    provider { 'azure_oauth' }
    uid { access_id }
    actor { build :actor, psu_id: access_id }
  end
end
