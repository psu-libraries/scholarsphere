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

  sequence(:work_title) do |n|
    a = Faker::Lorem.words(rand(1..5)).join(' ').capitalize
    b = Faker::Lorem.words.join(', ')
    c = Faker::Lorem.words.join("'s ")
    id = n.ordinalize

    %(#{a}: "#{b}; #{id} #{c}")
  end
end
