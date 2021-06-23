# frozen_string_literal: true

class WorkVersionDetailComponent < ApplicationComponent
  attr_reader :work_version

  def initialize(work_version:)
    @work_version = work_version
  end

  delegate :work, to: :work_version

  def render?
    work_version.draft? || !current_representative_version?
  end

  def i18n_key
    if work_version.draft?
      'draft_version'
    else
      'old_version'
    end
  end

  def current_representative_version?
    work_version.uuid == work_version.work.representative_version.uuid
  end
end
