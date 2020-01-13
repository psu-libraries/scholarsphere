# frozen_string_literal: true

require 'action_view/component'

class WorkHistories::FileMembershipChangeComponent < ActionView::Component::Base
  validates :paper_trail_version,
            :user,
            presence: true

  # @param paper_trail_version [PaperTrail::Version] representing a change to a
  #        FileVersionMembership
  # @param user [User]
  def initialize(paper_trail_version:, user:)
    if paper_trail_version.item_type != 'FileVersionMembership'
      raise ArgumentError, 'paper_trail_version must apply to a FileVersionMembership'
    end

    @paper_trail_version = paper_trail_version
    @user = user
  end

  private

    attr_reader :paper_trail_version,
                :user

    def element_id
      "change_#{paper_trail_version.id}"
    end

    def event_class
      return 'create' if create?
      return 'rename' if rename?
      return 'update' if update?
      return 'delete' if destroy?
    end

    def action
      return translate('rename') if rename?

      translate(paper_trail_version.event)
    end

    def timestamp
      paper_trail_version.created_at.to_s(:long)
    end

    def user_name
      user.access_id.presence || I18n.t('dashboard.work_history.unknown_user')
    end

    def current_filename
      return paper_trail_object['title'] if destroy?
      return paper_trail_object_changes['title'].last if create?

      paper_trail_object_changes.fetch('title', []).last ||
        paper_trail_object['title']
    end

    def previous_filename
      return nil unless rename?

      paper_trail_object_changes.fetch('title', []).first
    end

    def create?
      paper_trail_version.event == 'create'
    end

    def update?
      paper_trail_version.event == 'update' && !rename?
    end

    def rename?
      paper_trail_version.event == 'update' && paper_trail_object_changes.key?('title')
    end

    def destroy?
      paper_trail_version.event == 'destroy'
    end

    def translate(key, options = {})
      I18n.t("dashboard.work_history.file_membership.#{key}", options)
    end

    def paper_trail_object
      paper_trail_version.object || {}
    end

    def paper_trail_object_changes
      paper_trail_version.object_changes || {}
    end
end
