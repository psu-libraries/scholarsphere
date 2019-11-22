# frozen_string_literal: true

# @abstract Loads the edit history for a particular Work, and returns
# appropriately decorated objects for easy view rendering
class WorkHistoryPresenter
  attr_reader :work

  # @param Work
  def initialize(work)
    @work = work
    @user_lookup_cache = {}
  end

  def latest_work_version
    @latest_work_version ||= Dashboard::WorkVersionDecorator.new(work.latest_version)
  end

  # @returns a two dimensional array, where dimension 1 is all the WorkVersion
  # objects in the given Work, and dimension 2 is all the changes affecting that
  # WorkVersion returned as presenter objects
  #
  # @example Given a Work with two versions
  # > WorkHistoryPresenter.new(work).changes_by_work_version
  # => [
  #      [
  #        WorkVersion
  #        [ WorkVersionChangePresenter, WorkVersionChangePresenter, ...]
  #      ],
  #      [
  #        WorkVersion
  #        [ WorkVersionChangePresenter, WorkVersionChangePresenter, ...]
  #      ],
  #    ]
  def changes_by_work_version
    @changes_by_work_version ||= load_changes
  end

  private

    attr_reader :user_lookup_cache

    def load_changes
      work
        .versions
        .map do |work_version|
          changes = work_version.versions.map do |paper_trail_version|
            WorkVersionChangePresenter.new(
              paper_trail_version: paper_trail_version,
              user: lookup_user(paper_trail_version.whodunnit)
            )
          end

          [Dashboard::WorkVersionDecorator.new(work_version), changes]
        end
    end

    def lookup_user(user_id)
      user_lookup_cache[user_id] ||= find_user(user_id)
    end

    def find_user(user_id)
      User.find(user_id)
    rescue ActiveRecord::RecordNotFound
      null_user
    end

    # Null Object Pattern here used to prevent "undefined method x for nil" in
    # the view
    def null_user
      User.new.tap(&:readonly!)
    end
end
