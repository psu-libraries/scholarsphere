# frozen_string_literal: true

class WorkHistories::PaperTrailChangeBaseComponent < ApplicationComponent
  # @param paper_trail_version [PaperTrail::Version] representing a change to a
  #        Authorship
  # @param user [User]
  def initialize(paper_trail_version:, user:)
    if paper_trail_version.item_type.to_s != expected_item_type.to_s
      raise ArgumentError, "paper_trail_version must apply to a #{expected_item_type}"
    end

    @paper_trail_version = paper_trail_version
    @user = user
  end

  private

    # Implement these in your subclass

    # Which key under `dashboard.work_history` should we find the translations?
    def i18n_key
      raise NotImplementedError, 'Implement #i18n_key in your subclass'
    end

    # This is the type of object that your component is expecting.
    # For example, if your component was representing changes to a
    # FileVersionMembership object, set this method to "FileVersionMembership"
    def expected_item_type
      raise NotImplementedError, '''
        Implement #expected_item_type in your subclass. For details on what it
        does and how to set it, see the note in PaperTrailChangeBaseComponent
      '''.squish
    end

    attr_reader :paper_trail_version,
                :user

    def element_id
      "change_#{paper_trail_version.id}"
    end

    def event_class
      return 'create' if create?
      return 'update' if update?
      return 'delete' if destroy?
    end

    def action
      translate(paper_trail_event)
    end

    def timestamp
      paper_trail_version.created_at.to_s(:long)
    end

    def user_name
      user.access_id.presence || I18n.t('dashboard.work_history.unknown_user')
    end

    def create?
      paper_trail_event == 'create'
    end

    def update?
      paper_trail_event == 'update'
    end

    def destroy?
      paper_trail_event == 'destroy'
    end

    def paper_trail_event
      paper_trail_version.event
    end

    def paper_trail_object
      paper_trail_version.object || {}
    end

    def paper_trail_object_changes
      paper_trail_version.object_changes || {}
    end

    def translate(key, options = {})
      I18n.t("dashboard.work_history.#{i18n_key}.#{key}", options)
    end
end
