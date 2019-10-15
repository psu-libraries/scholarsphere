# frozen_string_literal: true

FactoryBot.define do
  factory :work do
    association :depositor, factory: :user
    work_type { Work::Types.all.first }

    # The Work model automatically builds an empty WorkVersion with empty
    # attributes. Unfortunately that makes this factory invalid, so we set a
    # title here if none is given
    after(:build) do |work|
      work.versions.first&.title ||= generate(:work_title)
    end
  end

  sequence(:work_title) { |n| "Work Version #{n}" }
end
