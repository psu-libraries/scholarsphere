# frozen_string_literal: true

FactoryBot.define do
  factory :work_version do
    work
    version_name { '1' }
    aasm_state { WorkVersion::STATE_DRAFT }
    title { generate(:work_title) }
  end
end
