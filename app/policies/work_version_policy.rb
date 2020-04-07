# frozen_string_literal: true

# @note this is a policy used by the public-facing side of the app. The
# Dashboard (where users work on their own stuff) has a different policy. At
# some point we may combine the two, but don't want to prefactor
class WorkVersionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def show?
    record.work.read_access? user
  end

  def download?
    return true if editable?
    return download_published_version? if record.published?

    false
  end

  private

    # @todo There's a bug in the permissions because a depositor should have edit access by default
    def editable?
      record.work.edit_access?(user) || record.depositor == user.actor
    end

    def download_published_version?
      return false if record.embargoed?

      record.work.read_access? user
    end
end
