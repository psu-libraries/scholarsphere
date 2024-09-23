# frozen_string_literal: true

class FileVersionMembershipPolicy < ApplicationPolicy
  def download?
    Pundit.policy(user, work_version).download?
  end

  def content?
    download?
  end

  def work_version
    @work_version ||= record.work_version
  end

  def destroy?
    return false if record.new_record?
    return true if user.admin?

    !record.work_version.published? && editable?
  end

  private

    def editable?
      Pundit.policy(user, record.work_version.work).edit?
    end
end
