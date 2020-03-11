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
end
