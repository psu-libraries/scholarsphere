# frozen_string_literal: true

class WorkVersionDetailComponent < ApplicationComponent
  attr_reader :work_version

  def initialize(work_version:)
    @work_version = work_version
  end

  def render?
    !current_draft_version? && i18n_key.present?
  end

  def i18n_key
    if draft_version.present?
      'draft_version'
    elsif representative_version.published? && (work_version.uuid != representative_version.uuid)
      'old_version'
    end
  end

  def linked_version
    if draft_version.present?
      work_version.work.draft_version.uuid
    elsif representative_version.published?
      work_version.work.uuid
    end
  end

  private

    def representative_version
      @representative_version ||= work_version.work.representative_version
    end

    def draft_version
      @draft_version ||= begin
                           unless Pundit.policy(controller.current_user, work_version.work).edit?
                             return NullWorkVersion.new
                           end

                           work_version.work.draft_version || NullWorkVersion.new
                         end
    end

    def current_draft_version?
      work_version.uuid == draft_version.uuid
    end
end
