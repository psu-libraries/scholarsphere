# frozen_string_literal: true

module WorkHistories
  class WorkHistoryComponent < ApplicationComponent
    # @param work [Work]
    def initialize(work:)
      @work = work
      @user_lookup_cache = {}
    end

    private

      attr_reader :work,
                  :user_lookup_cache

      # @returns a two dimensional array, where dimension 1 is all the WorkVersion
      # objects in the given Work, and dimension 2 is all the changes affecting that
      # WorkVersion returned as the hashes needed to render their components
      #
      # @example Given a Work with two versions
      # > WorkHistoryPresenter.new(work).changes_by_work_version
      # => [
      #      [
      #        WorkVersionDecorator
      #        [ WorkVersionChangeComponent, FileMembershipChangeComponent, ...]
      #      ],
      #      [
      #        WorkVersionDecorator
      #        [ WorkVersionChangeComponent, FileMembershipChangeComponent, ...]
      #      ],
      #    ]
      def changes_by_work_version
        @changes_by_work_version ||= load_changes
      end

      def load_changes
        work
          .versions
          .map do |work_version|
            decorated_work_version = WorkVersionDecorator.new(work_version)

            changes = (
              changes_to_work_version(work_version) +
              changes_to_work_versions_files(work_version) +
              changes_to_creators(work_version)
            ).sort_by { |h| h.dig(:locals, :paper_trail_version).created_at }

            [decorated_work_version, changes]
          end
      end

      # Accepts a WorkVersion, loads all the PaperTrail::Versions of it, then
      # maps it into a Hash with everything we need to render the component.
      #
      # @param [WorkVersion]
      # @return [Hash<WorkVersionChangeComponent, PaperTrail::Version, User>]
      def changes_to_work_version(work_version)
        work_version.versions.map do |paper_trail_version|
          {
            component: WorkVersionChangeComponent,
            locals: {
              paper_trail_version: paper_trail_version,
              user: lookup_user(paper_trail_version.whodunnit)
            }
          }
        end
      end

      # Accepts a WorkVersion, queries the database for all the
      # PaperTrail::Versions of that WorkVersion's FileVersionMemberships
      # (some of which may have been deleted), and wraps each one in a
      # Hash with everything we need to render the component.
      #
      # @param [WorkVersion]
      # @return [Hash<FileMembershipChangePresenter, PaperTrail::Version, User>]
      def changes_to_work_versions_files(work_version)
        PaperTrail::Version
          .where(
            item_type: 'FileVersionMembership',
            resource_id: work_version.id,
            resource_type: 'WorkVersion'
          )
          .map do |paper_trail_version|
            {
              component: FileMembershipChangeComponent,
              locals: {
                paper_trail_version: paper_trail_version,
                user: lookup_user(paper_trail_version.whodunnit)
              }
            }
          end
      end

      # Accepts a WorkVersion, queries the database for all the
      # PaperTrail::Versions of that WorkVersion's WorkVersionCreations
      # (some of which may have been deleted), and wraps each one in a
      # Hash with everything we need to render the component.
      #
      # @param [WorkVersion]
      # @return [Hash<CreatorChangeComponent, PaperTrail::Version, User>]
      def changes_to_creators(work_version)
        PaperTrail::Version
          .where(item_type: 'Authorship', resource_id: work_version.id, resource_type: 'WorkVersion')
          .map do |paper_trail_version|
            {
              component: CreatorChangeComponent,
              locals: {
                paper_trail_version: paper_trail_version,
                user: lookup_user(paper_trail_version.whodunnit)
              }
            }
          end
      end

      def lookup_user(global_id)
        user_lookup_cache[global_id] ||= find_user_or_app(global_id)
      end

      # @return [User, ExternalApp]
      def find_user_or_app(global_id)
        GlobalID::Locator.locate(global_id) || null_user
      rescue ActiveRecord::RecordNotFound
        null_user
      end

      # Null Object Pattern here used to prevent "undefined method x for nil" in
      # the view
      def null_user
        User.new.tap(&:readonly!)
      end
  end
end
