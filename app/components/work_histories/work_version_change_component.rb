# frozen_string_literal: true

require 'action_view/component'

class WorkHistories::WorkVersionChangeComponent < ActionView::Component::Base
  validates :paper_trail_version,
            :user,
            presence: true

  # @param paper_trail_version [PaperTrail::Version] representing a change to a
  #        WorkVersion
  # @param user [User]
  def initialize(paper_trail_version:, user:)
    if paper_trail_version.item_type != 'WorkVersion'
      raise ArgumentError, 'paper_trail_version must apply to a WorkVersion'
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

    def diff_id
      "change_diff_#{paper_trail_version.id}"
    end

    def action
      return translate('publish') if publish?

      translate(paper_trail_version.event)
    end

    def timestamp
      paper_trail_version.created_at.to_formatted_s(:long)
    end

    def user_name
      user.access_id.presence || I18n.t('dashboard.work_history.unknown_user')
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
      truncated << translate('truncated_attributes', count: remainder) if 0 < remainder
      truncated.join(', ')
    end

    # @todo make this its own component?
    def diff_presenter
      @diff_presenter ||= DiffPresenter.new(diff)
    end

    def publish?
      paper_trail_version.event == 'update' &&
        paper_trail_version.object_changes.fetch('aasm_state', []).last.to_s == WorkVersion::STATE_PUBLISHED.to_s
    end

    def update?
      paper_trail_version.event == 'update' && !publish?
    end

    def translate(key, options = {})
      I18n.t("dashboard.work_history.work_version.#{key}", options)
    end

    def diff
      @diff ||= WorkVersionChangeDiff.call(paper_trail_version)
    end
end
