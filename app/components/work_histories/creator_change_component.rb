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

    def current_name
      return paper_trail_object['display_name'] if destroy?
      return paper_trail_object_changes['display_name'].last if create?

      paper_trail_object_changes.fetch('display_name', []).last ||
        paper_trail_object['display_name']
    end

    def previous_name
      return nil unless rename?

      paper_trail_object_changes.fetch('display_name', []).first
    end

    def update?
      super && !rename?
    end

    def rename?
      paper_trail_version.event == 'update' && paper_trail_object_changes.key?('display_name')
    end

    def diff_id
      "change_diff_#{paper_trail_version.id}"
    end

    def diff_presenter
      @diff_presenter ||= DiffPresenter.new(diff)
    end

    def diff
      @diff ||= MetadataDiff.call(
        OpenStruct.new(metadata: { name: previous_name }),
        OpenStruct.new(metadata: { name: current_name })
      )
    end
end
