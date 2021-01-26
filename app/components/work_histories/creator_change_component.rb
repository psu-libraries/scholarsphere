# frozen_string_literal: true

class WorkHistories::CreatorChangeComponent < WorkHistories::PaperTrailChangeBaseComponent
  private

    def i18n_key
      'creator'
    end

    def expected_item_type
      'Authorship'
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

    def diff_id
      "change_diff_#{paper_trail_version.id}"
    end

    def diff_presenter
      @diff_presenter ||= DiffPresenter.new(diff)
    end

    def diff
      @diff ||= MetadataDiff.call(
        OpenStruct.new(metadata: { name: previous_alias }),
        OpenStruct.new(metadata: { name: current_alias })
      )
    end
end
