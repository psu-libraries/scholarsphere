# frozen_string_literal: true

FactoryBot.define do
  factory :api_token do
    application
    token { nil } # Typically generated in an after_initialize
  end
end
