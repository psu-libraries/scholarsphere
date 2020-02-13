# frozen_string_literal: true

class WorkHistories::CreatorAliasChangeComponent < WorkHistories::PaperTrailChangeBaseComponent
  # This apparently is a little quirk of ActionView::Component, and requires an
  # explicit #initialize method on each class.
  def initialize(**args)
    super
  end

  private

    def i18n_key
      'creator_alias'
    end

    def expected_item_type
      'WorkVersionCreation'
    end

    def event_class
      return 'rename' if rename?

      super
    end

    def action
      return translate('rename') if rename?

      super
    end

    def current_alias
      return paper_trail_object['alias'] if destroy?
      return paper_trail_object_changes['alias'].last if create?

      paper_trail_object_changes.fetch('alias', []).last ||
        paper_trail_object['alias']
    end

    def previous_alias
      return nil unless rename?

      paper_trail_object_changes.fetch('alias', []).first
    end

    def update?
      super && !rename?
    end

    def rename?
      paper_trail_version.event == 'update' && paper_trail_object_changes.key?('alias')
    end
end
