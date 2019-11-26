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
  #        WorkVersionDecorator
  #        [ WorkVersionChangePresenter, FileMembershipChangePresenter, ...]
  #      ],
  #      [
  #        WorkVersionDecorator
  #        [ WorkVersionChangePresenter, FileMembershipChangePresenter, ...]
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
          decorated_work_version = Dashboard::WorkVersionDecorator.new(work_version)

          change_presenters = (
            changes_to_work_version(work_version) +
            changes_to_work_versions_files(work_version)
          ).sort_by(&:created_at)

          [decorated_work_version, change_presenters]
        end
    end

    # Accepts a WorkVersion, loads all the PaperTrail::Versions of it, then
    # wraps each one in a WorkVersionChangePresenter.
    #
    # @param [WorkVersion]
    # @return [Array<WorkVersionChangePresenter>]
    def changes_to_work_version(work_version)
      work_version.versions.map do |paper_trail_version|
        WorkVersionChangePresenter.new(
          paper_trail_version: paper_trail_version,
          user: lookup_user(paper_trail_version.whodunnit)
        )
      end
    end

    # Accepts a WorkVersion, queries the database for all the
    # PaperTrail::Versions of that WorkVersion's FileVersionMemberships
    # (some of which may have been deleted), and wraps each one in a
    # FileMembershipChangePresenter.
    #
    # @param [WorkVersion]
    # @return [Array<FileMembershipChangePresenter>]
    def changes_to_work_versions_files(work_version)
      PaperTrail::Version
        .where(item_type: 'FileVersionMembership', work_version_id: work_version.id)
        .map do |paper_trail_version|
          FileMembershipChangePresenter.new(
            paper_trail_version: paper_trail_version,
            user: lookup_user(paper_trail_version.whodunnit)
          )
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
