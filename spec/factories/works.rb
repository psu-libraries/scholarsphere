# frozen_string_literal: true

FactoryBot.define do
  factory :work do
    depositor factory: %i[actor with_user]
    work_type { Work::Types.default }
    visibility { Permissions::Visibility.default }

    # Postgres does this for us, but for testing, we can do it here to save having to call create/reload.
    uuid { SecureRandom.uuid }

    transient do
      has_draft { true }
      versions_count { 1 }
    end

    # A work is not valid unless it has one or more versions. This block
    # automatically creates some versions—-if none already exist!--and allows
    # configuration for the number of versions to create, and whether one of
    # them should be a draft or not.
    after(:build) do |work, evaluator|
      next if work.versions.any? # Skip if there are already versions specified

      num_drafts_to_build = evaluator.has_draft ? 1 : 0
      num_published_to_build = evaluator.versions_count - num_drafts_to_build

      # We are going to use these to create the same actors across all the
      # authorships in all the work versions we create below, so that the
      # authors will stay the same across versions
      author_actors = build_list(:actor, 2)

      num_published_to_build.times do |n|
        work.versions << build(:work_version,
                               :published,
                               :with_complete_metadata,
                               work: work,
                               version_number: (n + 1),
                               creators: author_actors.each_with_index.map do |actor, index|
                                           Authorship.new(actor: actor, position: index + 1)
                                         end)
      end

      if evaluator.has_draft
        work.versions << build(:work_version,
                               :draft,
                               :with_complete_metadata,
                               work: work,
                               version_number: (num_published_to_build + 1),
                               creators: author_actors.each_with_index.map do |actor, index|
                                           Authorship.new(actor: actor, position: index + 1)
                                         end)

      end
    end
  end

  sequence(:work_title) do |n|
    FactoryBotHelpers.work_title(n)
  end

  trait(:with_no_access) do
    after(:create) do |work|
      work.access_controls.destroy_all
    end
  end

  trait(:withdrawn) do
    after(:create) do |work|
      work.latest_published_version.withdraw!
    end
  end

  trait(:with_authorized_access) do
    visibility { Permissions::Visibility::AUTHORIZED }
  end

  trait(:with_private_access) do
    visibility { Permissions::Visibility::PRIVATE }
  end

  trait(:article) do
    work_type { 'article' }
  end

  trait(:instrument) do
    work_type { 'instrument' }
  end

  trait(:masters_culminating_experience) do
    work_type { 'masters_culminating_experience' }
  end

  trait(:general) do
    work_type { 'audio' }
  end
end
