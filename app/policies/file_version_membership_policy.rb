# frozen_string_literal: true

class FileVersionMembershipPolicy < ApplicationPolicy
  def download?
    return true if edit?
    return download_published_version? if work_version.published?

    false
  end

  def content?
    download?
  end

  private

    # @todo There's a bug in the permissions because a depositor should have edit access by default
    def edit?
      work_version.work.edit_access?(user) || work_version.depositor == user
    end

    def download_published_version?
      return false if work_version.embargoed?

      work_version.work.read_access? user
    end

    def work_version
      @work_version ||= record.work_version
    end
end
