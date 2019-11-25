# frozen_string_literal: true

class FileMembershipChangePresenter
  attr_reader :paper_trail_version,
              :user

  # @param PaperTrail::Version representing a change to a FileVersionMembership
  # @param User
  def initialize(paper_trail_version:, user:)
    if paper_trail_version.item_type != 'FileVersionMembership'
      raise ArgumentError, 'paper_trail_version must apply to a FileVersionMembership'
    end

    @paper_trail_version = paper_trail_version
    @user = user
  end

  delegate :created_at,
           :event,
           :id,
           to: :paper_trail_version

  def to_partial_path
    'file_membership_change'
  end

  def action
    return t('rename') if rename?

    case event
    when 'create' then t('create')
    when 'destroy' then t('destroy')
    else "#{event}d".titleize
    end
  end

  def timestamp
    created_at.to_s(:long)
  end

  def current_filename
    return paper_trail_object['title'] if event == 'destroy'
    return paper_trail_object_changes['title'].last if event == 'create'

    paper_trail_object_changes.fetch('title', []).last ||
      paper_trail_object['title']
  end

  def previous_filename
    return nil unless rename?

    paper_trail_object_changes.fetch('title', []).first
  end

  def rename?
    event == 'update' && paper_trail_object_changes.key?('title')
  end

  private

    def t(key)
      I18n.t("dashboard.work_history.file_membership.#{key}")
    end

    def paper_trail_object
      paper_trail_version.object || {}
    end

    def paper_trail_object_changes
      paper_trail_version.object_changes || {}
    end
end
