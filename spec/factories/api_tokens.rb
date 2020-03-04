# frozen_string_literal: true

FactoryBot.define do
  factory :api_token do
    token { nil } # Typically generated in an after_initialize
    app_name { 'My Client Application' }
    admin_email { 'admin@client.app' }
  end
end
