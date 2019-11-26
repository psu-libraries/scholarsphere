# frozen_string_literal: true

# @abstract provides convenience methods and logic needed to render a change to
# a WorkVersion on the Work History timeline
class WorkVersionChangePresenter
  attr_reader :paper_trail_version,
              :user

  # @param PaperTrail::Version representing a change to a WorkVersion
  # @param User
  def initialize(paper_trail_version:, user:)
    if paper_trail_version.item_type != 'WorkVersion'
      raise ArgumentError, 'paper_trail_version must apply to a WorkVersion'
    end

    @paper_trail_version = paper_trail_version
    @user = user
  end

  delegate :created_at,
           :event,
           :id,
           to: :paper_trail_version

  def to_partial_path
    'work_version_change'
  end

  def action
    return t('publish') if publish?

    t(event)
  end

  def timestamp
    created_at.to_s(:long)
  end

  def changed_attributes
    return [] unless update?

    diff.keys.map do |attr|
      WorkVersion.human_attribute_name(attr)
    end
  end

  def changed_attributes_truncated(count = 3)
    truncated = changed_attributes.first(count)
    remainder = changed_attributes.length - truncated.length
    truncated << t('truncated_attributes', count: remainder) if remainder > 0
    truncated
  end

  def diff_presenter
    @diff_presenter ||= DiffPresenter.new(diff)
  end

  def create?
    paper_trail_version.event == 'create'
  end

  def update?
    paper_trail_version.event == 'update' && !publish?
  end

  def publish?
    paper_trail_version.event == 'update' &&
      paper_trail_version.object_changes.fetch('aasm_state', []).last == WorkVersion::STATE_PUBLISHED
  end

  private

    def t(key, options = {})
      I18n.t("dashboard.work_history.work_version.#{key}", options)
    end

    def diff
      @diff ||= WorkVersionChangeDiff.call(paper_trail_version)
    end
end
