# frozen_string_literal: true

FactoryBot.define do
  factory :featured_resource, aliases: [:featured_work] do
    resource factory: %i[work], has_draft: false

    resource_uuid { resource.uuid }

    factory :featured_work_version do
      resource { association :work_version, :published }
    end

    factory :featured_collection do
      resource factory: %i[collection]
    end
  end
end
