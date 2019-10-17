# frozen_string_literal: true

FactoryBot.define do
  factory :file_version_membership do
    work_version
    file_resource
  end
end
