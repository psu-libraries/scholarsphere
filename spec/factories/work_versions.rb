# frozen_string_literal: true

FactoryBot.define do
  factory :work_version do
    work
    version_name { '1' }
    aasm_state { 'draft' }
    title { generate(:work_title) }
  end
end
