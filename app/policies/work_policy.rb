# frozen_string_literal: true

class WorkPolicy < ApplicationPolicy
  class Scope < Scope
    def limit
      scope.all
    end
  end

  def show?
    published? || editable?
  end

  def edit?
    editable?
  end

  def update?
    edit?
  end

  # @note Even though this is not imposed at the database level, no one should be able to create a
  # new version if a draft one already exists.
  def create_version?
    editable? && record.draft_version.blank?
  end

  # @note we are temporarily disabling DOIs on draft works for launch. This
  # method should probably go away when we re-enable them
  def mint_doi?
    published? && editable?
  end

  private

    def editable?
      owner? || proxy? || record.edit_access?(user) || user.admin?
    end

    def owner?
      record.depositor == user.actor
    end

    def proxy?
      return false if record.proxy_depositor.nil?

      record.proxy_depositor == user.actor
    end

    def published?
      record.latest_published_version.present?
    end
end
