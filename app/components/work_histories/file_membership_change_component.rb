# frozen_string_literal: true

class WorkHistories::FileMembershipChangeComponent < WorkHistories::PaperTrailChangeBaseComponent
  # This apparently is a little quirk of ActionView::Component, and requires an
  # explicit #initialize method on each class.
  def initialize(**args)
    super
  end

  private

    def i18n_key
      'file_membership'
    end

    def expected_item_type
      'FileVersionMembership'
    end

    def event_class
      return 'rename' if rename?

      super
    end

    def action
      return translate('rename') if rename?

      super
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

    def update?
      super && !rename?
    end

    def rename?
      paper_trail_version.event == 'update' && paper_trail_object_changes.key?('title')
    end
end
